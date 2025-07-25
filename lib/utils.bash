#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for superdb.
GH_REPO="https://github.com/brimdata/super"
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
	awk '{print $1}' "${plugin_dir}/scripts/versions.txt"
}

lookup_version_sha() {
	local version="$1"
	awk -v ver="$version" '$1 == ver {print $2}' "${plugin_dir}/scripts/versions.txt"
}

download_release() {
	local -r version="$1"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

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

		go install github.com/brimdata/super/cmd/super@"$install_ref"

		mkdir -p "$install_path"

		# TODO: consider saving the current bin/super if there is one, then
		#  restoring it and using `mv` instead of `cp`

		if [ -x "${GOBIN:-}/super" ]; then
			cp -v -r "$GOBIN/super" "$install_path"
		fi

		if [ -x "${GOPATH:-}/bin/super" ]; then
			cp -v -r "$GOPATH/bin/super" "$install_path"
		fi

		# TODO: Assert superdb executable exists.
		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
