#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for superdb.
GH_REPO="https://github.com/brimdata/super"
RELEASE_GH_REPO="https://github.com/chrismo/superdb-builds"
TOOL_NAME="superdb"
TOOL_TEST="super --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if superdb is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	# Read versions from versions.txt file (first column only)
	# shellcheck disable=SC2154
	grep -v '#' "${plugin_dir}/scripts/versions.txt" |
		egrep '.' |
		awk '{print $1}'
}

lookup_version_sha() {
	local version="$1"
	# shellcheck disable=SC2154
	awk -v ver="$version" '$1 == ver {print $2}' "${plugin_dir}/scripts/versions.txt"
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

	local -r os=$(uname | tr "[:upper:]" "[:lower:]")

	local arch
	arch=$(uname -m | tr "[:upper:]" "[:lower:]")
	case $arch in
	aarch64 | arm64) arch="arm64" ;;
	esac

	url="$RELEASE_GH_REPO/releases/download/${version}/super-${version}-${os}-${arch}"

	echo "* Downloading $TOOL_NAME release $version..."
	if ! curl "${curl_opts[@]}" -o "$filename" -C - "$url"; then
		echo "Failed to download $TOOL_NAME $version from $url"
		return 0 # we don't want to stop things, we want to fall through to build
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
	if [[ -f "$downloaded_binary" ]] && [[ -x "$downloaded_binary" ]]; then
		echo "* Using downloaded $TOOL_NAME $version binary..."

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
			fail "Version $version not found"
		fi
	elif [ "$install_type" == "ref" ]; then
		install_ref="$version"
	fi

	(
		echo "* Building $TOOL_NAME $version from github.com/brimdata/super ..."

		if ! go install github.com/brimdata/super/cmd/super@"$install_ref"; then
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
