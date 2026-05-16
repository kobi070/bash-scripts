#!/bin/bash

# Script to find and optionally delete artifacts in JFrog Artifactory older than N days.
# Usage: ./jf_cleanup_old_artifacts.sh <repo_name> <days_old> [--delete]
# Example: ./jf_cleanup_old_artifacts.sh generic-local 30 --delete

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <repo_name> <days_old> [--delete]"
    echo "  repo_name: The Artifactory repository to search in."
    echo "  days_old: Minimum age of artifacts in days."
    echo "  --delete: (optional) Actually perform the deletion. Default is dry-run."
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

REPO=$1
DAYS=$2
DELETE_MODE="false"

if [[ "${3:-}" == "--delete" ]]; then
    DELETE_MODE="true"
fi

echo "Searching for artifacts in '$REPO' older than $DAYS days..."

# Use AQL (Artifactory Query Language) via the CLI to find old artifacts
# Note: 'created' is used for age.
AQL_QUERY="items.find({\"repo\": \"$REPO\", \"created\": {\"\$lt\": \"$DAYS\"}})"
# Wait, AQL uses relative time differently in CLI sometimes or ISO dates.
# The 'jf rt search' supports --created filter which is easier.

# The --created filter accepts a duration like "1mo", "30d", etc.
CREATED_FILTER="<$DAYS""d"

if [ "$DELETE_MODE" == "true" ]; then
    echo "WARNING: DELETE mode is enabled. Artifacts WILL be removed."
    $JF_BIN rt delete "$REPO/*" --created="$CREATED_FILTER"
else
    echo "DRY-RUN: Listing artifacts that would be deleted..."
    $JF_BIN rt search "$REPO/*" --created="$CREATED_FILTER"
fi

echo "Cleanup process completed."
