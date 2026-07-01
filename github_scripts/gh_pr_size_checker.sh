#!/bin/bash

# Script to categorize open Pull Requests in a GitHub repository by size.
# Size is determined by the total number of additions and deletions.
# Usage: ./gh_pr_size_checker.sh <owner/repo>
# Example: ./gh_pr_size_checker.sh kubernetes/kubernetes
# Bolt optimization: Uses GitHub GraphQL API to fetch all PR data in a single O(1) request.

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

# Ensure repository is in owner/repo format
if [[ "$REPO" != */* ]] || [[ -z "$OWNER" ]] || [[ -z "$NAME" ]]; then
    echo "Error: Invalid repository format. Use 'owner/repo'."
    exit 1
fi

echo "Fetching open PRs for $REPO via GraphQL..."

# GraphQL query to fetch PR details in bulk
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

# Safely construct the compact JSON payload
JSON_PAYLOAD=$(jq -n -c \
  --arg query "$QUERY" \
  --arg owner "$OWNER" \
  --arg name "$NAME" \
  '{query: $query, variables: {owner: $owner, name: $name}}')

# Escape backslashes and double quotes for curl config parser
# We use -c in jq to keep it on a single line, as curl -K data strings cannot contain literal newlines.
ESCAPED_PAYLOAD=$(echo "$JSON_PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Execute GraphQL request using curl config via stdin for security
RESPONSE=$(printf "header = \"Authorization: Bearer %s\"\nurl = \"https://api.github.com/graphql\"\ndata = \"%s\"" "$GITHUB_TOKEN" "$ESCAPED_PAYLOAD" | curl -s -K-)

# Check for errors in the GraphQL response
if echo "$RESPONSE" | jq -e '.errors' > /dev/null; then
    echo "Error from GitHub GraphQL API:"
    echo "$RESPONSE" | jq -r '.errors[0].message'
    exit 1
fi

PRS=$(echo "$RESPONSE" | jq -r '.data.repository.pullRequests.nodes')

if [ "$PRS" == "null" ] || [ "$PRS" == "[]" ]; then
    echo "No open PRs found for $REPO."
    exit 0
fi

PR_COUNT=$(echo "$PRS" | jq 'length')

echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

echo "$PRS" | jq -r '.[] | "\(.number)\t\(.title)\t\(.additions)\t\(.deletions)"' | while IFS=$'\t' read -r NUM TITLE ADDITIONS DELETIONS; do
    TOTAL=$((ADDITIONS + DELETIONS))

    SIZE="XS"
    if [ "$TOTAL" -ge 500 ]; then SIZE="XL";
    elif [ "$TOTAL" -ge 200 ]; then SIZE="L";
    elif [ "$TOTAL" -ge 50 ]; then SIZE="M";
    elif [ "$TOTAL" -ge 10 ]; then SIZE="S";
    fi

    # Truncate title if too long
    TRUNC_TITLE="${TITLE:0:47}"
    if [ "${#TITLE}" -gt 47 ]; then TRUNC_TITLE="${TRUNC_TITLE}..."; fi

    printf "%-10s %-50s %-10s %-10s\n" "#$NUM" "$TRUNC_TITLE" "$TOTAL" "$SIZE"
done

echo "--------------------------------------------------------------------------------"
echo "Size Legend: XS < 10, S < 50, M < 200, L < 500, XL >= 500 changes."
echo "Bolt Optimization: Reduced O(N) API calls to O(1) using GraphQL."
