#!/bin/bash

# Script to download a specific asset from the latest GitHub release of a repository.
# Useful for CI/CD pipelines to download pre-built binaries or artifacts.
# Usage: ./gh_download_release_asset.sh <owner/repo> <asset_name_pattern> [output_path]
# Example: ./gh_download_release_asset.sh argoproj/argo-cd "argocd-linux-amd64" "./argocd"
# Note: GITHUB_TOKEN environment variable can be used for authentication (required for private repos).

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> <asset_name_pattern> [output_path]"
    echo "  owner/repo: The GitHub repository (e.g., hashicorp/terraform)"
    echo "  asset_name_pattern: String pattern to match the asset name"
    echo "  output_path: (optional) Path to save the downloaded asset"
    echo "  Note: GITHUB_TOKEN environment variable can be used for authentication."
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

REPO=$1
PATTERN=$2
OUTPUT_PATH=${3:-$(basename "$PATTERN")}

echo "Searching for latest release asset matching '$PATTERN' in $REPO..."

# Get latest release JSON
# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps)
if [ -n "${GITHUB_TOKEN:-}" ]; then
    RELEASE_JSON=$(printf "header = \"Authorization: Bearer %s\"\n" "$GITHUB_TOKEN" | curl -s -K- -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$REPO/releases/latest")
else
    RELEASE_JSON=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$REPO/releases/latest")
fi

# Check for errors in response
if echo "$RELEASE_JSON" | jq -e '.message?' > /dev/null; then
    MESSAGE=$(echo "$RELEASE_JSON" | jq -r '.message')
    echo "Error from GitHub API: $MESSAGE"
    exit 1
fi

# Extract asset info
# We get both the API url (for authenticated downloads) and the browser_download_url (for public downloads)
ASSET_INFO=$(echo "$RELEASE_JSON" | jq -r --arg pattern "$PATTERN" '.assets[] | select(.name | contains($pattern)) | "\(.url)\t\(.browser_download_url)\t\(.name)"' | head -n 1)

if [ -z "$ASSET_INFO" ]; then
    echo "Error: Could not find an asset matching '$PATTERN' in the latest release of $REPO."
    echo "Available assets:"
    echo "$RELEASE_JSON" | jq -r '.assets[].name'
    exit 1
fi

API_URL=$(echo "$ASSET_INFO" | cut -f1)
BROWSER_URL=$(echo "$ASSET_INFO" | cut -f2)
ASSET_NAME=$(echo "$ASSET_INFO" | cut -f3)

echo "Found asset: $ASSET_NAME"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "Downloading asset via API URL for authenticated access..."
    # When using a token, we must use the API URL and Accept: application/octet-stream
    # https://docs.github.com/en/rest/releases/assets#get-a-release-asset
    printf "header = \"Authorization: Bearer %s\"\n" "$GITHUB_TOKEN" | \
        curl -L -sS -K- -H "Accept: application/octet-stream" -o "$OUTPUT_PATH" "$API_URL"
else
    echo "Downloading asset via Browser Download URL..."
    curl -L -o "$OUTPUT_PATH" "$BROWSER_URL"
fi

echo "Download completed successfully: $OUTPUT_PATH"
chmod +x "$OUTPUT_PATH" 2>/dev/null || true
