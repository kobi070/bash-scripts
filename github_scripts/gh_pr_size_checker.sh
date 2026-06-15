#!/bin/bash

# Script to categorize open Pull Requests in a GitHub repository by size.
# Size is determined by the total number of additions and deletions.
# Optimized with Bolt: Uses a single GraphQL query to reduce process forks from O(N) to O(1).
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
REPO_NAME="${REPO#*/}"

if [[ "$OWNER" == "$REPO" ]]; then
    echo "Error: Repository must be in 'owner/repo' format."
    exit 1
fi

echo "Fetching open PRs for $REPO via GraphQL..."

# GraphQL query to fetch PR details in bulk
# We fetch the first 100 open PRs.
QUERY='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        number
        title
        additions
        deletions
      }
    }
  }
}'

# Construct JSON payload using compact output for curl compatibility
JSON_PAYLOAD=$(jq -nc \
  --arg query "$QUERY" \
  --arg owner "$OWNER" \
  --arg name "$REPO_NAME" \
  '{query: $query, variables: {owner: $owner, name: $name}}')

# Escape the payload for use in curl's -K- configuration
ESCAPED_PAYLOAD=$(echo "$JSON_PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Execute GraphQL request
# Bolt: Use curl -K- for secure token handling and consolidated API call.
RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\ndata = \"%s\"\n" "$GITHUB_TOKEN" "$ESCAPED_PAYLOAD" | \
    curl -s -K- -H "Content-Type: application/json" \
    "https://api.github.com/graphql")

# Check for errors in response
if echo "$RESPONSE" | jq -e '.errors' > /dev/null; then
    echo "Error: GitHub API returned errors:"
    echo "$RESPONSE" | jq -r '.errors[].message'
    exit 1
fi

# Bolt optimization: Consolidate categorization and formatting into a single jq pipeline.
# This eliminates shell loops and multiple printf forks for large PR lists.
RESULT=$(echo "$RESPONSE" | jq -r '
  .data.repository.pullRequests.nodes |
  if length == 0 then empty else .[] end |
  .number as $num |
  (.additions + .deletions) as $total |
  (if $total >= 500 then "XL"
   elif $total >= 200 then "L"
   elif $total >= 50 then "M"
   elif $total >= 10 then "S"
   else "XS" end) as $size |
  .title as $title |
  ($title[0:47] + (if ($title | length) > 47 then "..." else "" end)) as $trunc_title |
  "\($num)\t\($trunc_title)\t\($total)\t\($size)"
')

if [ -z "$RESULT" ]; then
    echo "No open PRs found for $REPO."
    exit 0
fi

PR_COUNT=$(echo "$RESULT" | wc -l)

echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

# Format output using printf for alignment
while IFS=$'\t' read -r num title total size; do
    printf "%-10s %-50s %-10s %-10s\n" "#$num" "$title" "$total" "$size"
done <<< "$RESULT"

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
