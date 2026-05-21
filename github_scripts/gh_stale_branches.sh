#!/bin/bash

# Script to identify stale remote branches in a GitHub repository.
# Useful for repository maintenance and identifying abandoned work.
# Usage: ./gh_stale_branches.sh [owner/repo] [days]
# Example: ./gh_stale_branches.sh google/guava 90

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [owner/repo] [days]"
    echo "  owner/repo: (optional) The GitHub repository. Default: current repo"
    echo "  days: (optional) Threshold for stale branches in days. Default: 30"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v gh &> /dev/null; then
    echo "Error: gh CLI is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

REPO="${1:-}"
THRESHOLD_DAYS="${2:-30}"
CURRENT_TS=$(date +%s)

REPO_ARG=""
if [ -n "$REPO" ]; then
    REPO_ARG="-R $REPO"
fi

echo "Fetching branches for $REPO..."
echo "----------------------------------------------------------------------------------------------------"
printf "%-30s %-15s %-25s %-20s\n" "BRANCH" "AGE (DAYS)" "LAST COMMIT" "AUTHOR"
echo "----------------------------------------------------------------------------------------------------"

# Get branches with last commit date
# Use gh api for high performance and better data access
gh api $REPO_ARG /repos/:owner/:repo/branches --paginate | jq -c '.[]' | while read -r branch; do
    BRANCH_NAME=$(echo "$branch" | jq -r '.name')
    COMMIT_URL=$(echo "$branch" | jq -r '.commit.url')

    # Get last commit details
    COMMIT_INFO=$(gh api "$COMMIT_URL")
    LAST_COMMIT_DATE=$(echo "$COMMIT_INFO" | jq -r '.commit.committer.date')
    LAST_COMMIT_AUTHOR=$(echo "$COMMIT_INFO" | jq -r '.commit.committer.name')

    # Parse date and calculate age
    # Ensure date is quoted for jq
    LAST_COMMIT_TS=$(echo "\"$LAST_COMMIT_DATE\"" | jq -r 'fromdate')
    AGE_SECONDS=$((CURRENT_TS - LAST_COMMIT_TS))
    AGE_DAYS=$((AGE_SECONDS / 86400))

    if [ "$AGE_DAYS" -ge "$THRESHOLD_DAYS" ]; then
        printf "%-30s %-15s %-25s %-20s\n" "$BRANCH_NAME" "$AGE_DAYS" "$LAST_COMMIT_DATE" "$LAST_COMMIT_AUTHOR"
    fi
done | sort -k2 -n -r
