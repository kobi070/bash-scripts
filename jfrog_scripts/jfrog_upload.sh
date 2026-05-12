#!/bin/bash

# Script to upload files or directories to a JFrog Artifactory repository using the CLI.
# Usage: ./jfrog_upload.sh <source_path> <target_repo_path> [recursive]
# Example: ./jfrog_upload.sh "./dist/*.zip" "generic-local/my-app/v1.0.0/" true

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <source_path> <target_repo_path> [recursive]"
    echo "  source_path: Local path or wildcard pattern to upload"
    echo "  target_repo_path: Destination path in Artifactory (including repo name)"
    echo "  recursive: (optional) Set to 'true' for recursive upload. Default: true"
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

SOURCE_PATH=$1
TARGET_PATH=$2
RECURSIVE=${3:-true}

echo "Uploading $SOURCE_PATH to $TARGET_PATH (recursive: $RECURSIVE)..."

# Perform the upload
$JF_BIN rt upload "$SOURCE_PATH" "$TARGET_PATH" --recursive="$RECURSIVE"

echo "Upload completed successfully."
