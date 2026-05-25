#!/bin/bash

# Script to list open pull requests for a GitHub repository using the API.
# Useful for automation tasks that need to track active PRs.
# Usage: ./gh_list_pull_requests.sh <owner/repo> [state]
# Example: ./gh_list_pull_requests.sh kubernetes/kubernetes open
# Note: GITHUB_TOKEN environment variable is recommended for private repos or to avoid rate limits.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> [state]"
    echo "  owner/repo: The GitHub repository"
    echo "  state: (optional) open, closed, or all. Default: open"
    echo ""
    echo "Note: GITHUB_TOKEN environment variable is recommended for private repos or to avoid rate limits."
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

REPO=$1
STATE=${2:-open}
API_URL="https://api.github.com/repos/$REPO/pulls?state=$STATE"

echo "Fetching $STATE pull requests for $REPO..."

# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps)
# Sentinel philosophy: Secure by default.
if [ -n "${GITHUB_TOKEN:-}" ]; then
    PRS=$(printf "header = \"Authorization: Bearer %s\"\n" "$GITHUB_TOKEN" | \
        curl -s -K- -H "Accept: application/vnd.github+json" "$API_URL")
else
    PRS=$(curl -s -H "Accept: application/vnd.github+json" "$API_URL")
fi

# Check for API errors
if echo "$PRS" | jq -e '.message?' > /dev/null; then
    ERROR_MSG=$(echo "$PRS" | jq -r '.message')
    echo "Error from GitHub API: $ERROR_MSG"
    exit 1
fi

if [ "$PRS" == "[]" ] || [ -z "$PRS" ]; then
    echo "No $STATE pull requests found for $REPO."
    exit 0
fi

# Output as a table using printf for better portability than the 'column' command
# Bolt philosophy: Efficient line processing
printf "%-10s %-20s %s\n" "NUMBER" "USER" "TITLE"
printf "%-10s %-20s %s\n" "------" "----" "-----"

echo "$PRS" | jq -r '.[] | "\(.number)\t\(.user.login)\t\(.title | gsub("\n"; " "))"' | while IFS=$'\t' read -r number user title; do
    printf "%-10s %-20s %s\n" "$number" "$user" "$title"
done
