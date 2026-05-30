#!/bin/bash

# Script to increment version numbers in a file.
# Supported parts: major, minor, patch.
# Usage: ./bump_version.sh <file> [part]
# Example: ./bump_version.sh version.txt patch

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <file> [part]"
    echo "  file: The file containing the version string (x.y.z)"
    echo "  part: major, minor, or patch. Default: patch"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if [ "$#" -lt 1 ]; then
    usage
fi

FILE=$1
PART=${2:-patch}

if [ ! -f "$FILE" ]; then
    echo "Error: File $FILE not found." >&2
    exit 1
fi

# Get the version from the file
# We look for a semantic version pattern x.y.z
VERSION=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' "$FILE" | head -n 1) || true

if [ -z "$VERSION" ]; then
    echo "Error: No valid version (x.y.z) found in $FILE." >&2
    exit 1
fi

# Split the version into major, minor, and patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Perform the bump
case "$PART" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Error: Unknown part: $PART. Use major, minor, or patch." >&2
        exit 1
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Escape dots in VERSION for sed to ensure exact matching
ESCAPED_VERSION=$(echo "$VERSION" | sed 's/\./\\./g')

# Replace in file (using a temporary file for portability of sed -i)
# We use a specific replacement to avoid matching partial versions if possible
sed "s/$ESCAPED_VERSION/$NEW_VERSION/g" "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

echo "Old version: v$VERSION"
echo "New version: v$NEW_VERSION"
echo "🔁 Bumped $PART version: $VERSION → $NEW_VERSION"
