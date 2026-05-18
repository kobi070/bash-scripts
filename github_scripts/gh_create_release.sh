#!/bin/bash

# Script to create a GitHub release via the API.
# Useful for automating releases in CI/CD pipelines.
# Usage: ./gh_create_release.sh <owner/repo> <tag_name> [release_name] [body]
# Example: ./gh_create_release.sh my-org/my-repo v1.0.0 "Release v1.0.0" "Initial release description"

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> <tag_name> [release_name] [body]"
    echo "  owner/repo: The GitHub repository"
    echo "  tag_name: The tag to create the release for"
    echo "  release_name: (optional) The title of the release"
    echo "  body: (optional) The description of the release"
    echo "  Note: Requires GITHUB_TOKEN environment variable."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 2 ]; then
    usage
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    exit 1
fi

REPO=$1
TAG=$2
NAME=${3:-$TAG}
BODY=${4:-"Release $TAG"}

echo "Creating GitHub release for $REPO at tag $TAG..."

# Prepare the JSON payload
PAYLOAD=$(jq -n \
    --arg tag "$TAG" \
    --arg name "$NAME" \
    --arg body "$BODY" \
    '{tag_name: $tag, name: $name, body: $body, draft: false, prerelease: false}')

# Send the request
# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps)
RESPONSE=$(printf "header = \"Authorization: token %s\"\n" "$GITHUB_TOKEN" | curl -s -X POST -K- \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$PAYLOAD" \
    "https://api.github.com/repos/$REPO/releases")

# Check for errors
if echo "$RESPONSE" | jq -e '.id' > /dev/null; then
    RELEASE_ID=$(echo "$RESPONSE" | jq -r '.id')
    RELEASE_URL=$(echo "$RESPONSE" | jq -r '.html_url')
    echo "Success: Release created successfully."
    echo "ID: $RELEASE_ID"
    echo "URL: $RELEASE_URL"
else
    echo "Error: Failed to create release."
    echo "$RESPONSE" | jq .
    exit 1
fi
