#!/bin/bash

# Script to delete artifacts from JFrog Artifactory using the CLI.
# Supports dry-run and recursive deletion.
# Usage: ./jfrog_delete.sh <pattern> [--dry-run] [--recursive]
# Example: ./jfrog_delete.sh "generic-local/my-app/old-builds/*" --dry-run

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <pattern> [--dry-run] [--recursive]"
    echo "  pattern: The pattern of artifacts to delete"
    echo "  --dry-run: (optional) Only show what would be deleted"
    echo "  --recursive: (optional) Set to 'true' or 'false'. Default: true"
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
if [ "$#" -lt 1 ]; then
    usage
fi

PATTERN=$1
DRY_RUN="false"
RECURSIVE="true"

# Parse optional arguments
for arg in "$@"; do
    if [ "$arg" == "--dry-run" ]; then
        DRY_RUN="true"
    elif [[ "$arg" == "--recursive=false" ]]; then
        RECURSIVE="false"
    elif [[ "$arg" == "--recursive" ]]; then
        RECURSIVE="true"
    fi
done

echo "Deleting artifacts matching: $PATTERN (dry-run: $DRY_RUN, recursive: $RECURSIVE)..."

# Perform the deletion
$JF_BIN rt delete "$PATTERN" --dry-run="$DRY_RUN" --recursive="$RECURSIVE" --quiet

echo "Delete process completed."
