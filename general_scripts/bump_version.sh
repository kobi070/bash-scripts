#!/bin/bash

# TODO: Add another arg to mabey update by more than one

# Example Usage: 
# ./bump_version.sh version.txt patch
# ./bump_version.sh version.txt minor
# ./bump_version.sh version.txt major

# Get the args from the user
# file - Which file do you want to get the version from
# part - Which part of the version in the file do you want to update

file=$1
part=${2:-patch} # default: patch

# Get the version and saving it in version varibale
version=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' "$file")

# IFS - split the major.minor.patch to not havve "." 
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
patch) ((patch++)) ;;
*)
    echo "Unknown part: $part"
    exit 1
    ;;
esac

# The new version after the updated state
new_version="${major}.${minor}.${patch}"

# Replace in file
sed -i.bak "s/$version/$new_version/" "$file"

echo "Old version: v$(version)"
echo "New version: v$(new_version)"
echo "🔁 Bumped $part version: $version → $new_version"
