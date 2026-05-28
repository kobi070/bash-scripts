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

# Security check: Ensure DAYS is a numeric integer to prevent shell arithmetic injection
if [[ ! "$DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: days must be a positive numeric integer."
    exit 1
fi

THRESHOLD_SEC=$((DAYS * 24 * 3600))

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

# Bolt optimization: Consolidate date parsing and staleness check into a single jq pipeline.
# This reduces process forks from O(N) to O(1) and uses portable jq date functions.
# We pipe the full JSON to jq instead of using gh --jq to allow complex processing in one pass.
gh api graphql -f query="$QUERY" -f owner="$OWNER" -f name="$NAME" | \
jq -r --argjson threshold "$THRESHOLD_SEC" '
  .data.repository.refs.nodes[] |
  .name as $name |
  .target.committedDate as $date |
  ($date | fromdateiso8601) as $commit_sec |
  (now - $commit_sec) as $age_sec |
  ($age_sec / 86400 | floor) as $age_days |
  select($age_sec > $threshold) |
  "\($name)\t\($date)\t\($age_days)"
' | while IFS=$'\t' read -r branch_name commit_date age_days; do
    printf "%-30s %-25s %-10s\n" "$branch_name" "$commit_date" "$age_days"
done

echo "--------------------------------------------------------------------------------"
