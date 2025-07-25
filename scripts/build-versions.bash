#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/brimdata/super.git"
REPO_NAME="super"
OUTPUT_FILE="versions.txt"
TEMP_DIR=$(mktemp -d)

cleanup() {
	echo "Cleaning up temporary directory: $TEMP_DIR"
	rm -rf "$TEMP_DIR"
}

# trap cleanup EXIT

echo "Cloning brimdata/super repository..."
cd "$TEMP_DIR"
git clone --quiet "$REPO_URL" "$REPO_NAME"
cd "$REPO_NAME"

echo "Extracting commit information..."
output_path="$TEMP_DIR/$OUTPUT_FILE"

# a36339b8 is around the 1st zq -> super commit
git log --pretty=format:"%H %cd" --date=format:"%y.%m.%d" a36339b8..HEAD | while read -r commit_sha commit_date; do
	echo -n '.' >&2
	short_sha=$(echo "$commit_sha" | cut -c1-7)
	version_string="0.0.$commit_date"
	echo "$version_string $short_sha" >>"$output_path"
done

echo "Post-processing to keep only last entry of each month..."

# Process to keep only last entry of each month
# Extract year-month and sort by it, keeping last occurrence
sed 's/^0\.0\.\(..\)\.\(..\)\..* \(.*\)/\1.\2 0.0.\1.\2 \3/' "$output_path" | sort -k1,1 -u | sed 's/^[^ ]* //' > "${output_path}.tmp"

mv "${output_path}.tmp" "$output_path"

echo "Moving output file to current directory..."
mv "$output_path" "/Users/chrismo/modev/asdf-superdb/scripts/$OUTPUT_FILE"

echo "Analysis complete! Results written to $OUTPUT_FILE"
echo "File contains $(wc -l <"/Users/chrismo/modev/asdf-superdb/scripts/$OUTPUT_FILE") commit entries"
