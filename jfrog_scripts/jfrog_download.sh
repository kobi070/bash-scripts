#!/bin/bash

# Script to download files or directories from a JFrog Artifactory repository using the CLI.
# Usage: ./jfrog_download.sh <repo_path> <local_dest_path> [recursive]
# Example: ./jfrog_download.sh "generic-local/my-app/v1.0.0/*" "./downloads/" true

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <repo_path> <local_dest_path> [recursive]"
    echo "  repo_path: Path in Artifactory (including repo name)"
    echo "  local_dest_path: Local destination directory"
    echo "  recursive: (optional) Set to 'true' for recursive download. Default: true"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI (jf or jfrog) is not installed or not in PATH."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

# Input validation
if [ "$#" -lt 2 ]; then
    usage
fi

REPO_PATH=$1
LOCAL_DEST=$2
RECURSIVE=${3:-true}

echo "Downloading $REPO_PATH to $LOCAL_DEST (recursive: $RECURSIVE)..."

# Perform the download
$JF_BIN rt download "$REPO_PATH" "$LOCAL_DEST" --recursive="$RECURSIVE"

echo "Download completed successfully."
