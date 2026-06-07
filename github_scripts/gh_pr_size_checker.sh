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

REPO=$1

echo "Fetching open PRs for $REPO..."

OWNER="${REPO%/*}"
NAME="${REPO#*/}"

# GraphQL query to fetch PRs and their size metrics in a single O(1) call
QUERY='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes { number title additions deletions }
    }
  }
}'
PAYLOAD=$(jq -n -c --arg q "$QUERY" --arg o "$OWNER" --arg n "$NAME" '{query: $q, variables: {owner: $o, name: $n}}')
ESCAPED_PAYLOAD=$(echo "$PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Bolt optimization: consolidated O(N) REST calls into a single O(1) GraphQL request
RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\ndata = \"%s\"" "$GITHUB_TOKEN" "$ESCAPED_PAYLOAD" | \
    curl -s -K- -H "Content-Type: application/json" "https://api.github.com/graphql")

if echo "$RESPONSE" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error from GitHub GraphQL API: $(echo "$RESPONSE" | jq -r '.errors[0].message')"
    exit 1
fi

PRS=$(echo "$RESPONSE" | jq '.data.repository.pullRequests.nodes')
PR_COUNT=$(echo "$PRS" | jq 'length')

if [ "$PR_COUNT" -eq 0 ]; then
    echo "No open PRs found for $REPO."
    exit 0
fi

echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Consolidate arithmetic and categorization into a single jq pipeline
# This improves performance and prevents shell arithmetic injection.
echo "$PRS" | jq -r '
  .[] |
  .number as $num |
  (.title | gsub("\n"; " ")) as $title |
  (.additions + .deletions) as $tot |
  (if $tot >= 500 then "XL" elif $tot >= 200 then "L" elif $tot >= 50 then "M" elif $tot >= 10 then "S" else "XS" end) as $sz |
  ($title | if length > 47 then .[0:47] + "..." else . end) as $trunc |
  "#\($num)\t\($trunc)\t\($tot)\t\($sz)"
' | while IFS=$'\t' read -r num title total size; do
    printf "%-10s %-50s %-10s %-10s\n" "$num" "$title" "$total" "$size"
done

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
