#!/bin/bash

# Script to categorize open Pull Requests in a GitHub repository by size.
# Size is determined by the total number of additions and deletions.
# Part of the Bolt philosophy: Use GraphQL to reduce network calls from O(N) to O(1).
# Usage: ./gh_pr_size_checker.sh <owner/repo>
# Example: ./gh_pr_size_checker.sh kubernetes/kubernetes

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo>"
    echo "  owner/repo: The GitHub repository to check."
    echo "  Note: Requires GITHUB_TOKEN environment variable."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in curl jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    exit 1
fi

REPO=$1
OWNER="${REPO%/*}"
NAME="${REPO#*/}"

echo "Fetching open PRs for $REPO using GraphQL..."

# GraphQL query to fetch PR details in bulk
# Bolt optimization: Retrieve all necessary data (number, title, additions, deletions) in a single O(1) call.
QUERY="query {
  repository(owner: \"$OWNER\", name: \"$NAME\") {
    pullRequests(states: OPEN, first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        number
        title
        additions
        deletions
      }
    }
  }
}"

# Prepare JSON payload for GraphQL
# We use jq to safely encode the query string and ensure it is compact (single line)
# Bolt optimization: Compact JSON is required for curl config file format (-K-)
PAYLOAD=$(jq -nc --arg query "$QUERY" '{query: $query}')

# Fetch PRs from GitHub GraphQL API
# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps)
# Robustness: Escape double quotes and backslashes for curl config format
ESCAPED_PAYLOAD=$(echo "$PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')
RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\nheader = \"Accept: application/json\"\ndata = \"%s\"" "$GITHUB_TOKEN" "$ESCAPED_PAYLOAD" | \
    curl -s -K- "https://api.github.com/graphql")

# Check for GraphQL errors
if echo "$RESPONSE" | jq -e '.errors?' > /dev/null; then
    MESSAGE=$(echo "$RESPONSE" | jq -r '.errors[0].message')
    echo "Error from GitHub GraphQL API: $MESSAGE"
    exit 1
fi

# Check for API-level errors (e.g. Bad credentials)
if echo "$RESPONSE" | jq -e '.message?' > /dev/null; then
    MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
    echo "Error from GitHub API: $MESSAGE"
    exit 1
fi

PRS_DATA=$(echo "$RESPONSE" | jq -r '.data.repository.pullRequests.nodes')

if [ "$PRS_DATA" == "null" ] || [ "$(echo "$PRS_DATA" | jq 'length')" -eq 0 ]; then
    echo "No open PRs found for $REPO."
    exit 0
fi

PR_COUNT=$(echo "$PRS_DATA" | jq 'length')
echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Consolidate data extraction, size categorization, and title truncation into a single jq pipeline.
# This eliminates the O(N) loop with internal network calls and reduces process forks.
echo "$PRS_DATA" | jq -r '
  .[] |
  .number as $num |
  .title as $title |
  (.additions + .deletions) as $total |
  (if $total >= 500 then "XL"
   elif $total >= 200 then "L"
   elif $total >= 50 then "M"
   elif $total >= 10 then "S"
   else "XS" end) as $size |
  (if ($title | length) > 47 then ($title[0:47] + "...") else $title end) as $trunc_title |
  "#\($num)\t\($trunc_title)\t\($total)\t\($size)"
' | while IFS=$'\t' read -r num trunc_title total size; do
    printf "%-10s %-50s %-10s %-10s\n" "$num" "$trunc_title" "$total" "$size"
done

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
