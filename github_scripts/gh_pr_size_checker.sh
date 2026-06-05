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

# Fetch open PRs (first 100)
PRS=$(printf "header = \"Authorization: Bearer %s\"\n" "$GITHUB_TOKEN" | \
    curl -s -K- -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/pulls?state=open&per_page=100")

# Check if PRS is an array
if ! echo "$PRS" | jq -e 'if type == "array" then . else error("Not an array") end' > /dev/null 2>&1; then
    echo "Error: Failed to fetch PRs or repository not found."
    echo "$PRS" | jq -c .
    exit 1
fi

PR_COUNT=$(echo "$PRS" | jq '. | length')

if [ "$PR_COUNT" -eq 0 ]; then
    echo "No open PRs found for $REPO."
    exit 0
fi

echo "Analyzing $PR_COUNT PRs..."
echo "--------------------------------------------------------------------------------"
printf "%-10s %-50s %-10s %-10s\n" "PR #" "TITLE" "CHANGES" "SIZE"
echo "--------------------------------------------------------------------------------"

echo "$PRS" | jq -r '.[] | [.number, .title, .url] | @tsv' | while IFS=$'\t' read -r NUM TITLE URL; do
    # Fetch PR details for additions/deletions
    DETAILS=$(printf "header = \"Authorization: Bearer %s\"\n" "$GITHUB_TOKEN" | \
        curl -s -K- -H "Accept: application/vnd.github.v3+json" \
        "$URL")

    ADDITIONS=$(echo "$DETAILS" | jq -r '.additions // 0')
    DELETIONS=$(echo "$DETAILS" | jq -r '.deletions // 0')
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
