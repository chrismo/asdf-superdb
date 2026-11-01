#!/usr/bin/env bash

# plugin_dir is set by the calling script before sourcing this file
# shellcheck disable=SC2154

set -euo pipefail

GH_REPO="https://github.com/chrismo/superdb-builds"
OFFICIAL_GH_REPO="https://github.com/superdb/super"
TOOL_NAME="superdb"
TOOL_TEST="super --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

# Add GitHub API token if available for higher rate limits
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

lookup_version_sha() {
	local version="$1"
	awk -v ver="$version" '$1 == ver {print $2}' "${plugin_dir}/scripts/versions.txt"
}

# Pre-release builds are versioned 0.YMMDD and all predate 0.1.0.
PRERELEASE_RE='^0\.[0-9]{5}$'
# 0.1.x and 0.2.x are unlisted but still install if pinned.
UNLISTED_RELEASE_RE='^0\.[0-2]\.'

print_license_notice() {
	local install_type="$1" version="$2"
	[ "$install_type" == "version" ] || return 0

	# SuperDB moved from BSD-3-Clause to the Source Available License at 0.3.0.
	if [[ "$version" =~ $PRERELEASE_RE || "$version" =~ $UNLISTED_RELEASE_RE ]]; then
		echo "Distributed under the terms of the BSD-3-Clause License (https://github.com/superdb/super/blob/v0.2.0/LICENSE.txt)"
	else
		echo "Distributed under the terms of the SuperDB Source Available License v1.0 (https://github.com/superdb/super/blob/v${version}/LICENSE.md)"
	fi
}

list_all_versions() {
	# Pre-release versions from versions.txt
	grep -v '#' "${plugin_dir}/scripts/versions.txt" |
		grep -E '.' |
		awk '{print $1}'
	# Official releases from superdb/super
	local official_url="https://api.github.com/repos/superdb/super/releases"
	curl "${curl_opts[@]}" "$official_url" 2>/dev/null |
		grep -oE '"tag_name": *"[^"]+"' |
		sed 's/"tag_name": *"v\{0,1\}\([^"]*\)"/\1/' |
		grep -vE "$UNLISTED_RELEASE_RE" || true
}

download_prerelease() {
	local version filename url
	version="$1"
	filename="$2"

	local -r os=$(uname | tr "[:upper:]" "[:lower:]")

	local arch
	arch=$(uname -m | tr "[:upper:]" "[:lower:]")
	case $arch in
	x86_64 | amd64 | x86-64 | x64) arch="amd64" ;;
	aarch64 | arm64) arch="arm64" ;;
	esac

	url="$GH_REPO/releases/download/${version}/super-${version}-${os}-${arch}"

	echo "* Downloading $TOOL_NAME pre-release $version..."
	if ! curl "${curl_opts[@]}" -o "$filename" -C - "$url"; then
		echo "Failed to download $TOOL_NAME $version from $url"
		return 1
	fi

	# Verify the downloaded binary
	if ! verify_binary "$filename"; then
		echo "Downloaded binary verification failed, will build from source"
		rm -f "$filename"
		return 1
	fi

	echo "Binary downloaded and verified successfully"
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

	local -r os=$(uname | tr "[:upper:]" "[:lower:]")

	local arch
	arch=$(uname -m | tr "[:upper:]" "[:lower:]")
	case $arch in
	x86_64 | amd64 | x86-64 | x64) arch="amd64" ;;
	aarch64 | arm64) arch="arm64" ;;
	esac

	# Release binaries are plain executables
	local binary_name="super-${version}-${os}-${arch}"
	url="$GH_REPO/releases/download/${version}/${binary_name}"

	echo "* Downloading $TOOL_NAME release $version..."
	if ! curl "${curl_opts[@]}" -o "$filename" -C - "$url"; then
		echo "Failed to download $TOOL_NAME $version from $url"
		return 1 # download failed
	fi

	# Verify the downloaded binary
	if ! verify_binary "$filename"; then
		echo "Downloaded binary verification failed, will build from source"
		rm -f "$filename" # Remove invalid binary
		return 1          # verification failed
	fi

	echo "Binary downloaded and verified successfully"
}

download_official_release() {
	local version filename
	version="$1"
	filename="$2"

	local -r os=$(uname | tr "[:upper:]" "[:lower:]")

	local arch
	arch=$(uname -m | tr "[:upper:]" "[:lower:]")
	case $arch in
	x86_64 | amd64 | x86-64 | x64) arch="amd64" ;;
	aarch64 | arm64) arch="arm64" ;;
	esac

	# Official releases are tar.gz archives: super-v{version}.{os}-{arch}.tar.gz
	local archive_name="super-v${version}.${os}-${arch}.tar.gz"
	local url="$OFFICIAL_GH_REPO/releases/download/v${version}/${archive_name}"

	echo "* Downloading $TOOL_NAME official release $version..."
	local tmpdir
	tmpdir=$(mktemp -d)
	local archive_file="$tmpdir/$archive_name"

	if ! curl "${curl_opts[@]}" -o "$archive_file" -C - "$url"; then
		echo "Failed to download $TOOL_NAME $version from $url"
		rm -rf "$tmpdir"
		return 1
	fi

	# Extract the binary from the tar.gz archive
	if ! tar -xzf "$archive_file" -C "$tmpdir"; then
		echo "Failed to extract archive"
		rm -rf "$tmpdir"
		return 1
	fi

	# Find the super binary in the extracted contents
	local extracted_binary
	extracted_binary=$(find "$tmpdir" -name "super" -type f ! -name "*.tar.gz" | head -1)
	if [[ -z "$extracted_binary" ]]; then
		echo "Could not find super binary in archive"
		rm -rf "$tmpdir"
		return 1
	fi

	mv "$extracted_binary" "$filename"
	rm -rf "$tmpdir"

	# Verify the downloaded binary
	if ! verify_binary "$filename"; then
		echo "Downloaded binary verification failed, will build from source"
		rm -f "$filename"
		return 1
	fi

	echo "Binary downloaded and verified successfully"
}

verify_binary() {
	local binary_path="$1"

	# Check if file exists and is not empty
	[[ -s "$binary_path" ]] || return 1

	# Make binary executable first
	chmod +x "$binary_path" 2>/dev/null || {
		echo "Cannot make binary executable"
		return 1
	}

	# If file command is available, do format and architecture checks
	if command -v file >/dev/null 2>&1; then
		local file_type
		file_type=$(file "$binary_path" 2>/dev/null)

		# Check for executable binary indicators
		if [[ "$file_type" =~ (executable|ELF|Mach-O) ]]; then
			# Verify architecture matches system
			local system_arch
			system_arch=$(uname -m | tr "[:upper:]" "[:lower:]")
			case $system_arch in
			x86_64 | amd64 | x86-64 | x64) system_arch="amd64" ;;
			aarch64 | arm64) system_arch="arm64" ;;
			esac

			# Check if binary architecture matches system
			if [[ "$system_arch" == "arm64" && "$file_type" =~ (arm64|aarch64|arm64e) ]]; then
				:
			elif [[ "$system_arch" == "amd64" && "$file_type" =~ (x86-64|x86_64) ]]; then
				:
			elif [[ "$file_type" =~ "universal binary" ]]; then
				:
			else
				echo "Architecture mismatch: binary is for different architecture than system ($system_arch)"
				return 1
			fi
		else
			echo "Downloaded file is not a valid binary executable"
			return 1
		fi
	fi

	# Final verification: try to run super --version
	# This is the authoritative test - if it runs, it works
	if "$binary_path" --version >/dev/null 2>&1; then
		echo "Binary verification successful (execution test passed)"
		return 0
	else
		echo "Binary execution test failed (binary may be corrupted or incompatible)"
		return 1
	fi
}

verify_installation() {
	local install_path="$1"
	local version="$2"

	local tool_cmd
	tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
	test -x "$install_path/$tool_cmd" || return 1

	echo "$TOOL_NAME $version installation was successful!"
	return 0
}

install_downloaded() {
	local version="$1"
	local install_path="$2"

	local downloaded_binary="${ASDF_DOWNLOAD_PATH:-}/$TOOL_NAME-$version"
	if [[ -f "$downloaded_binary" ]]; then
		echo "* Using downloaded $TOOL_NAME $version binary..."

		# Double-check binary verification before installation
		if ! verify_binary "$downloaded_binary"; then
			echo "Binary verification failed during installation, will build from source"
			rm -f "$downloaded_binary"
			return 1
		fi

		# Make binary executable
		chmod +x "$downloaded_binary"

		mkdir -p "$install_path"
		mv -v "$downloaded_binary" "$install_path/super"

		verify_installation "$install_path" "$version" || return 1
	else
		return 1
	fi
}

build_from_sources() {
	local install_type="$1"
	local version="$2"
	local install_path="$3"

	local install_ref
	if [ "$install_type" == "version" ]; then
		install_ref=$(lookup_version_sha "$version")
		if [ -z "$install_ref" ]; then
			# Not a pre-release version, use version tag for official releases
			install_ref="v${version}"
		fi
	elif [ "$install_type" == "ref" ]; then
		install_ref="$version"
	fi

	(
		echo "* Building $TOOL_NAME $version from source..."

		# Module path is github.com/brimdata/super before v0.4.0.
		local superdb_err
		if ! superdb_err=$(go install "github.com/superdb/super/cmd/super@$install_ref" 2>&1) &&
			! go install "github.com/brimdata/super/cmd/super@$install_ref"; then
			echo "$superdb_err"
			fail "Failed to build $TOOL_NAME $version from source."
		fi

		mkdir -p "$install_path"

		# TODO: consider saving the current bin/super if there is one, then
		#  restoring it and using `mv` instead of `cp`

		if [ -x "${GOBIN:-}/super" ]; then
			cp -v -r "$GOBIN/super" "$install_path"
		elif [ -x "${GOPATH:-}/bin/super" ]; then
			cp -v -r "$GOPATH/bin/super" "$install_path"
		else
			echo "Couldn't find GOBIN or GOPATH. Dunno how to locate build output."
		fi

		verify_installation "$install_path" "$version" || fail "$TOOL_NAME $version build failed verification."
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	# Try to install from the downloaded binary first
	if install_downloaded "$version" "$install_path"; then
		return 0
	else
		# Fall back to building from source
		build_from_sources "$install_type" "$version" "$install_path"
	fi
}
