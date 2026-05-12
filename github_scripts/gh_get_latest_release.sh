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
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.tag_name')

if [ "$LATEST_RELEASE" == "null" ] || [ -z "$LATEST_RELEASE" ]; then
    echo "Error: Could not find the latest release for $REPO. Ensure the repo exists and has a release."
    exit 1
fi

echo "$LATEST_RELEASE"
