#!/bin/bash

# Script to delete GitHub Actions workflow runs older than a specified number of days.
# Helps in keeping the repository's Actions history clean.
# Usage: GITHUB_TOKEN=your_token ./gh_delete_old_workflow_runs.sh <owner/repo> [days_threshold]
# Example: GITHUB_TOKEN=ghp_... ./gh_delete_old_workflow_runs.sh myorg/myrepo 30

set -euo pipefail

# Help function
usage() {
    echo "Usage: GITHUB_TOKEN=your_token $0 <owner/repo> [days_threshold]"
    echo "  owner/repo: The target repository (e.g., 'octocat/hello-world')"
    echo "  days_threshold: (optional) Delete runs older than this many days. Default: 30"
    echo ""
    echo "Note: Requires GITHUB_TOKEN environment variable with 'repo' or 'actions' scope."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for cmd in curl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed or not in PATH."
        exit 1
    fi
done

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    exit 1
fi

# Check for GNU date (required for -d)
if ! date --version 2>/dev/null | grep -q "GNU"; then
    echo "Error: This script requires GNU date (available in coreutils on macOS)."
    exit 1
fi

REPO=$1
DAYS_THRESHOLD=${2:-30}
API_URL="https://api.github.com/repos/$REPO/actions/runs"

# Calculate threshold date in ISO 8601 format (YYYY-MM-DD)
THRESHOLD_DATE=$(date -d "$DAYS_THRESHOLD days ago" +%Y-%m-%d)

echo "Searching for workflow runs in '$REPO' older than $THRESHOLD_DATE ($DAYS_THRESHOLD days)..."

# Fetch runs
# Note: This handles the first page (up to 100 runs). For very large repositories or high frequency
# workflows, you may need to implement pagination.
RUNS_TO_DELETE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$API_URL?per_page=100" | \
    jq -r ".workflow_runs[] | select(.created_at < \"$THRESHOLD_DATE\") | .id")

if [ -z "$RUNS_TO_DELETE" ]; then
    echo "No old workflow runs found to delete."
    exit 0
fi

COUNT=0
for run_id in $RUNS_TO_DELETE; do
    echo "Deleting workflow run ID: $run_id"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$API_URL/$run_id")

    if [ "$RESPONSE" -eq 204 ]; then
        COUNT=$((COUNT + 1))
    else
        echo "Failed to delete run $run_id. HTTP Status: $RESPONSE"
    fi
done

echo "Successfully deleted $COUNT workflow runs."
