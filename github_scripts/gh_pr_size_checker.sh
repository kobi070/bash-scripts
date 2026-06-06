#!/bin/bash

# Script to categorize open Pull Requests in a GitHub repository by size.
# Size is determined by the total number of additions and deletions.
# Bolt Optimization: Replaces O(N) sequential REST API calls with a single O(1) GraphQL query.
# This reduces N+1 API requests and 3*N process forks to 1 request and 1 pipeline.
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

if [[ "$OWNER" == "$REPO" ]]; then
    echo "Error: Repository must be in 'owner/repo' format."
    exit 1
fi

echo "Fetching open PRs for $REPO..."

# Use GraphQL to fetch all necessary PR data in a single call
QUERY='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    pullRequests(states: OPEN, first: 100) {
      nodes {
        number
        title
        additions
        deletions
      }
    }
  }
}'

# Prepare the GraphQL payload safely
PAYLOAD=$(jq -n -c --arg query "$QUERY" --arg owner "$OWNER" --arg name "$NAME" \
    '{query: $query, variables: {owner: $owner, name: $name}}')

# Escape backslashes and double quotes for the curl config parser to prevent injection
ESCAPED_PAYLOAD=$(echo "$PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Execute single GraphQL request
RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\ndata = \"%s\"" "$GITHUB_TOKEN" "$ESCAPED_PAYLOAD" | \
    curl -s -K- "https://api.github.com/graphql")

# Check for GraphQL errors
if echo "$RESPONSE" | jq -e '.errors' > /dev/null; then
    echo "Error: GitHub API returned errors:"
    echo "$RESPONSE" | jq -r '.errors[].message'
    exit 1
fi

# Extract PRs
PR_DATA=$(echo "$RESPONSE" | jq '.data.repository.pullRequests.nodes')

if [[ "$PR_DATA" == "null" || "$PR_DATA" == "[]" ]]; then
    echo "No open PRs found for $REPO."
    exit 0
fi

PR_COUNT=$(echo "$PR_DATA" | jq 'length')

echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Perform arithmetic, categorization, and truncation entirely in jq.
# This eliminates per-iteration process forks and shell arithmetic.
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
  # Replace newlines in title with spaces to preserve tabular output
  ($title | gsub("\n"; " ")) as $clean_title |
  ($clean_title | if length > 47 then .[0:47] + "..." else . end) as $trunc_title |
  "#\($num)\t\($trunc_title)\t\($total)\t\($size)"
' | while IFS=$'\t' read -r num title total size; do
    printf "%-10s %-50s %-10s %-10s\n" "$num" "$title" "$total" "$size"
done

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
