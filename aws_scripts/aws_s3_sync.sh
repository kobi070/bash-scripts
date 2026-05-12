#!/bin/bash

# Script to sync a local directory with an S3 bucket.
# Useful for backups, static site deployments, or sharing artifacts.
# Usage: ./aws_s3_sync.sh <local_path> <s3_bucket_url> [--dry-run] [--delete]
# Example: ./aws_s3_sync.sh ./dist s3://my-bucket/artifacts/ --delete

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <local_path> <s3_bucket_url> [--dry-run] [--delete]"
    echo "  local_path: The local directory to sync"
    echo "  s3_bucket_url: The S3 bucket URL (e.g., s3://my-bucket/path/)"
    echo "  --dry-run: (optional) Only show what would be synced"
    echo "  --delete: (optional) Delete files in S3 that don't exist locally"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v aws &> /dev/null; then
    echo "Error: aws CLI is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 2 ]; then
    usage
fi

LOCAL_PATH=$1
S3_URL=$2

# Collect extra arguments
EXTRA_ARGS=""
for arg in "${@:3}"; do
    EXTRA_ARGS="$EXTRA_ARGS $arg"
done

echo "Syncing $LOCAL_PATH with $S3_URL..."

# Perform the sync
aws s3 sync "$LOCAL_PATH" "$S3_URL" $EXTRA_ARGS

echo "Sync process completed successfully."
