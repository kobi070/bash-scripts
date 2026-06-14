#!/bin/bash

# Script to categorize open Pull Requests in a GitHub repository by size.
# Size is determined by the total number of additions and deletions.
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
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    exit 1
fi

REPO_FULL=$1
OWNER=$(echo "$REPO_FULL" | cut -d'/' -f1)
REPO_NAME=$(echo "$REPO_FULL" | cut -d'/' -f2)

if [ -z "$OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "Error: Invalid repository format. Use owner/repo."
    exit 1
fi

echo "Fetching and analyzing open PRs for $REPO_FULL via GraphQL..."

# GraphQL query to fetch additions and deletions for the first 100 open PRs
# Bolt optimization: Consolidate N+1 REST calls into 1 GraphQL call.
QUERY="query {
  repository(owner: \"$OWNER\", name: \"$REPO_NAME\") {
    pullRequests(states: OPEN, first: 100) {
      nodes {
        number
        title
        additions
        deletions
      }
    }
  }
}"

# Package query into JSON and escape for curl config
JSON_QUERY=$(jq -nc --arg q "$QUERY" '{"query": $q}')
ESCAPED_QUERY=$(echo "$JSON_QUERY" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Fetch data using curl -K- pattern for security
RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\ndata = \"%s\"\n" "$GITHUB_TOKEN" "$ESCAPED_QUERY" | \
    curl -s -K- -H "Content-Type: application/json" "https://api.github.com/graphql")

# Check for GraphQL errors
if echo "$RESPONSE" | jq -e '.errors' > /dev/null; then
    echo "Error from GitHub GraphQL API:"
    echo "$RESPONSE" | jq -r '.errors[0].message'
    exit 1
fi

PR_DATA=$(echo "$RESPONSE" | jq -c '.data.repository.pullRequests.nodes')

if [ "$PR_DATA" == "null" ] || [ "$PR_DATA" == "[]" ]; then
    echo "No open PRs found for $REPO_FULL."
    exit 0
fi

PR_COUNT=$(echo "$PR_DATA" | jq 'length')
echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Consolidate arithmetic and formatting into a single jq pipeline.
# This eliminates the O(N) while-read loop and shell arithmetic.
echo "$PR_DATA" | jq -r '
  .[] |
  .number as $num |
  .title as $title |
  (.additions + .deletions) as $total |
  (if $total >= 500 then "XL"
   elif $total >= 200 then "L"
   elif $total >= 50 then "M"
   elif $total >= 10 then "S"
   else "XS" end) as $size |
  ([
    ("#\($num)"),
    (if ($title | length) > 47 then ($title | .[0:47] + "...") else $title end),
    ($total | tonumber),
    $size
  ] | @tsv)
' | while IFS=$'\t' read -r num title total size; do
    printf "%-10s %-50s %-10s %-10s\n" "$num" "$title" "$total" "$size"
done

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
