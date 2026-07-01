#!/bin/bash

# Script to calculate Pull Request statistics for a GitHub repository.
# It calculates the average time-to-merge for the last N merged pull requests.
# Requires GitHub CLI (gh) and jq.
# Usage: ./gh_pr_stats.sh [repo] [limit]
# Example: ./gh_pr_stats.sh my-org/my-repo 50

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [repo] [limit]"
    echo "  repo: (optional) Repository in 'owner/repo' format. Default: current repo"
    echo "  limit: (optional) Number of PRs to analyze. Default: 30"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in gh jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

ARGS=()
if [ "$#" -ge 1 ]; then
    ARGS+=("-R" "$1")
fi

LIMIT=${2:-30}

# Security Pattern: validate numeric input to prevent arithmetic injection
if [[ ! "$LIMIT" =~ ^[0-9]+$ ]]; then
    echo "Error: limit must be a positive integer."
    exit 1
fi

echo "Fetching statistics for the last $LIMIT merged PRs..."

# Fetch merged PRs with their creation and merge timestamps
# Bolt optimization: process data in a single jq pipeline
# Security Pattern: Use array for arguments to prevent injection
PR_DATA=$(gh pr list "${ARGS[@]}" --state merged --limit "$LIMIT" --json createdAt,mergedAt,title,number)

if [ "$(echo "$PR_DATA" | jq '. | length')" -eq 0 ]; then
    echo "No merged Pull Requests found."
    exit 0
fi

echo "--------------------------------------------------------------------------------"
echo "PR #   | Merged At            | Duration (Hours) | Title"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Move all date arithmetic and string manipulation into a single jq process.
# This eliminates 2x 'date' and 1x 'awk' process forks per pull request (3*N forks total).
# We calculate duration in hours and format fields directly in jq.
# The shell loop now only uses the 'printf' builtin for consistent decimal formatting.
echo "$PR_DATA" | jq -r '
  .[] |
  .number as $num |
  .mergedAt as $merged |
  .createdAt as $created |
  .title as $title |
  ((($merged | fromdateiso8601) - ($created | fromdateiso8601)) / 3600) as $diff_hours |
  "\($num)\t\($merged[0:19])\t\($diff_hours)\t\($title[0:40])"
' | while IFS=$'\t' read -r num merged diff_hours title; do
    printf "%-6s | %-20s | %-16.2f | %s\n" "$num" "$merged" "$diff_hours" "$title"
done

# Calculate overall average
# Bolt optimization: Reuse the already fetched PR_DATA
AVG_HOURS=$(echo "$PR_DATA" | jq -r '
  [ .[] | ( (.mergedAt | fromdateiso8601) - (.createdAt | fromdateiso8601) ) ] |
  if length > 0 then (add / length) / 3600 else 0 end
')

echo "--------------------------------------------------------------------------------"
echo "SUMMARY:"
echo "Analyzed PRs: $(echo "$PR_DATA" | jq '. | length')"
printf "Average Time-to-Merge: %.2f hours\n" "$AVG_HOURS"
echo "--------------------------------------------------------------------------------"
