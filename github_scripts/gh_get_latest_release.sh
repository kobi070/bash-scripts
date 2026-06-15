#!/bin/bash

# Script to fetch the latest release tag from a GitHub repository using the GitHub API.
# Useful for CI/CD pipelines to determine the version of a dependency to download.
# Usage: ./gh_get_latest_release.sh <owner/repo>
# Example: ./gh_get_latest_release.sh kubernetes/kubernetes

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo>"
    echo "  owner/repo: The GitHub repository (e.g., argoproj/argo-cd)"
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
if [ "$#" -ne 1 ]; then
    usage
fi

REPO=$1

# Fetch latest release from GitHub API
# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps)
if [ -n "${GITHUB_TOKEN:-}" ]; then
    # Security Pattern: Escape backslashes and double quotes for curl config parser
    ESCAPED_TOKEN=$(echo "$GITHUB_TOKEN" | sed 's/\\/\\\\/g; s/"/\\"/g')
    RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\n" "$ESCAPED_TOKEN" | curl -s -K- "https://api.github.com/repos/$REPO/releases/latest")
else
    RESPONSE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
fi

# Check for errors in response
if echo "$RESPONSE" | jq -e '.message?' > /dev/null; then
    MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
    echo "Error from GitHub API: $MESSAGE"
    exit 1
fi

LATEST_RELEASE=$(echo "$RESPONSE" | jq -r '.tag_name')

if [ "$LATEST_RELEASE" == "null" ] || [ -z "$LATEST_RELEASE" ]; then
    echo "Error: Could not find the latest release for $REPO. Ensure the repo exists and has a release."
    exit 1
fi

echo "$LATEST_RELEASE"
