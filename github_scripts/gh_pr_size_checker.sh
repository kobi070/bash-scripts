#!/bin/bash

# Script to categorize open Pull Requests in a GitHub repository by size.
# Size is determined by the total number of additions and deletions.
# Bolt optimization: Uses a single GitHub GraphQL query to reduce network calls from O(N) to O(1).
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
for tool in curl jq sed; do
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

if [[ "$OWNER" == "$REPO" || -z "$NAME" ]]; then
    echo "Error: Invalid repository format. Use 'owner/repo'."
    exit 1
fi

echo "Fetching open PRs for $REPO via GraphQL..."

# Bolt optimization: Construct a single GraphQL query to fetch PR details in bulk.
# This reduces the total network overhead from N+1 calls to 1 call.
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

# Prepare JSON payload safely using jq
JSON_PAYLOAD=$(jq -n -c --arg q "$QUERY" --arg owner "$OWNER" --arg name "$NAME" \
  '{query: $q, variables: {owner: $owner, name: $name}}')

# Use curl config via stdin to prevent secret leakage and handle potential large payloads.
# We must escape backslashes and double quotes for the curl config parser.
ESCAPED_PAYLOAD=$(echo "$JSON_PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')

RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\nurl = \"https://api.github.com/graphql\"\ndata = \"%s\"" "$GITHUB_TOKEN" "$ESCAPED_PAYLOAD" | curl -s -K-)

# Check for GraphQL errors
if echo "$RESPONSE" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error: GitHub API returned errors:"
    echo "$RESPONSE" | jq -r '.errors[].message'
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

# Bolt optimization: Consolidate all categorization and formatting logic into a single jq pipeline.
# This eliminates the O(N) shell loop and arithmetic forks.
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
  ($title | if length > 47 then .[0:47] + "..." else . end) as $trunc_title |
  "#\($num)\t\($trunc_title)\t\($total)\t\($size)"
' | while IFS=$'\t' read -r num title total size; do
    printf "%-10s %-50s %-10s %-10s\n" "$num" "$title" "$total" "$size"
done

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
