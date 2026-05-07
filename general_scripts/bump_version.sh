#!/bin/bash
set -euo pipefail

# Example Usage: 
# ./bump_version.sh version.txt patch
# ./bump_version.sh version.txt minor
# ./bump_version.sh version.txt major

usage() {
    echo "Usage: $0 <file> [major|minor|patch]"
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

file=$1
part=${2:-patch} # default: patch

if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found."
    exit 1
fi

# Get the version and saving it in version variable
# Only matching the first occurrence for simplicity and safety
version=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' "$file" | head -n 1)

if [ -z "$version" ]; then
    echo "Error: No version string (x.y.z) found in '$file'."
    exit 1
fi

# IFS - split the major.minor.patch
IFS='.' read -r major minor patch <<<"$version"

# Switch case for each of the parts based on the user choice
case "$part" in
major)
    ((major++))
    minor=0
    patch=0
    ;;
minor)
    ((minor++))
    patch=0
    ;;
patch)
    ((patch++))
    ;;
*)
    echo "Unknown part: $part. Use major, minor, or patch."
    exit 1
    ;;
esac

# The new version after the updated state
new_version="${major}.${minor}.${patch}"

# Replace in file
sed -i.bak "s/$version/$new_version/g" "$file"

echo "Old version: v$version"
echo "New version: v$new_version"
echo "🔁 Bumped $part version: $version → $new_version"
