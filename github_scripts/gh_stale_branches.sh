#!/bin/bash

# gh_stale_branches.sh - Identifies stale branches in a GitHub repository.
# A branch is considered stale if its last commit was more than N days ago.
# Part of the DevOps Automation Hub.

set -euo pipefail

DEFAULT_DAYS=30

usage() {
    echo "Usage: $0 <owner/repo> [days]"
    echo "  owner/repo: Target GitHub repository (e.g., jules/my-repo)"
    echo "  days: (optional) Threshold for staleness in days. Default: $DEFAULT_DAYS"
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if [ "$#" -lt 1 ]; then
    usage
fi

REPO=$1
DAYS=${2:-$DEFAULT_DAYS}
THRESHOLD_SEC=$((DAYS * 24 * 3600))
NOW_SEC=$(date +%s)

# Verify dependencies
for tool in gh jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

echo "Checking for branches in $REPO stale for more than $DAYS days..."
echo "--------------------------------------------------------------------------------"
printf "%-30s %-25s %-10s\n" "BRANCH" "LAST COMMIT" "AGE (DAYS)"
echo "--------------------------------------------------------------------------------"

# Use GraphQL to fetch branches and their last commit dates efficiently
QUERY='
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    refs(refPrefix: "refs/heads/", first: 100, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
      nodes {
        name
        target {
          ... on Commit {
            committedDate
          }
        }
      }
    }
  }
}'

OWNER="${REPO%/*}"
NAME="${REPO#*/}"

gh api graphql -f query="$QUERY" -f owner="$OWNER" -f name="$NAME" --jq '.data.repository.refs.nodes[]' | while read -r branch_json; do
    BRANCH_NAME=$(echo "$branch_json" | jq -r '.name')
    COMMIT_DATE=$(echo "$branch_json" | jq -r '.target.committedDate')

    # Calculate age
    COMMIT_SEC=$(date -d "$COMMIT_DATE" +%s 2>/dev/null || date -jf "%Y-%m-%dT%H:%M:%SZ" "$COMMIT_DATE" +%s)
    AGE_SEC=$((NOW_SEC - COMMIT_SEC))
    AGE_DAYS=$((AGE_SEC / 86400))

    if [ "$AGE_SEC" -gt "$THRESHOLD_SEC" ]; then
        printf "%-30s %-25s %-10s\n" "$BRANCH_NAME" "$COMMIT_DATE" "$AGE_DAYS"
    fi
done

echo "--------------------------------------------------------------------------------"
