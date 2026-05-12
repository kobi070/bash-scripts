#!/bin/bash

# Script to download a specific asset from the latest GitHub release of a repository.
# Useful for CI/CD pipelines to download pre-built binaries or artifacts.
# Usage: ./gh_download_release_asset.sh <owner/repo> <asset_name_pattern> [output_path]
# Example: ./gh_download_release_asset.sh argoproj/argo-cd "argocd-linux-amd64" "./argocd"

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> <asset_name_pattern> [output_path]"
    echo "  owner/repo: The GitHub repository (e.g., hashicorp/terraform)"
    echo "  asset_name_pattern: String pattern to match the asset name"
    echo "  output_path: (optional) Path to save the downloaded asset"
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
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

# Extract asset download URL
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r --arg pattern "$PATTERN" '.assets[] | select(.name | contains($pattern)) | .browser_download_url' | head -n 1)

if [ "$DOWNLOAD_URL" == "null" ] || [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find an asset matching '$PATTERN' in the latest release of $REPO."
    echo "Available assets:"
    echo "$RELEASE_JSON" | jq -r '.assets[].name'
    exit 1
fi

echo "Downloading asset from: $DOWNLOAD_URL"
echo "Saving to: $OUTPUT_PATH"

curl -L -o "$OUTPUT_PATH" "$DOWNLOAD_URL"

echo "Download completed successfully."
chmod +x "$OUTPUT_PATH" 2>/dev/null || true
