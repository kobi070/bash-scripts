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

REPO_ARG=""
if [ "$#" -ge 1 ]; then
    REPO_ARG="-R $1"
fi

LIMIT=${2:-30}

echo "Fetching statistics for the last $LIMIT merged PRs..."

# Fetch merged PRs with their creation and merge timestamps
# Bolt optimization: process data in a single jq pipeline
PR_DATA=$(gh pr list $REPO_ARG --state merged --limit "$LIMIT" --json createdAt,mergedAt,title,number)

if [ "$(echo "$PR_DATA" | jq '. | length')" -eq 0 ]; then
    echo "No merged Pull Requests found."
    exit 0
fi

echo "--------------------------------------------------------------------------------"
echo "PR #   | Merged At            | Duration (Hours) | Title"
echo "--------------------------------------------------------------------------------"

# Process PRs and calculate stats
# Note: We use awk for date arithmetic because bc is not available and bash lacks floating point
echo "$PR_DATA" | jq -r '.[] | "\(.number)\t\(.mergedAt)\t\(.createdAt)\t\(.title)"' | while IFS=$'\t' read -r num merged created title; do
    # Convert ISO 8601 to epoch (requires GNU date or compatible)
    CREATED_EPOCH=$(date -d "$created" +%s)
    MERGED_EPOCH=$(date -d "$merged" +%s)

    DIFF_SECONDS=$((MERGED_EPOCH - CREATED_EPOCH))
    # Using awk for division to get decimal hours
    DIFF_HOURS=$(awk "BEGIN {printf \"%.2f\", $DIFF_SECONDS / 3600}")

    printf "%-6s | %-20s | %-16s | %s\n" "$num" "${merged:0:19}" "$DIFF_HOURS" "${title:0:40}"
done

# Calculate overall average
AVG_HOURS=$(echo "$PR_DATA" | jq -r '.[] | .createdAt as $c | .mergedAt as $m | ( ($m | fromdateiso8601) - ($c | fromdateiso8601) )' | \
    awk '{ sum += $1; count++ } END { if (count > 0) printf "%.2f", (sum / count) / 3600; else print "0" }')

echo "--------------------------------------------------------------------------------"
echo "SUMMARY:"
echo "Analyzed PRs: $(echo "$PR_DATA" | jq '. | length')"
echo "Average Time-to-Merge: $AVG_HOURS hours"
echo "--------------------------------------------------------------------------------"
