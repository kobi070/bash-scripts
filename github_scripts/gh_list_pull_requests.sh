#!/bin/bash

# Script to list open pull requests for a GitHub repository using the API.
# Useful for automation tasks that need to track active PRs.
# Usage: ./gh_list_pull_requests.sh <owner/repo> [state]
# Example: ./gh_list_pull_requests.sh kubernetes/kubernetes open
# Note: GITHUB_TOKEN environment variable must be set for private repositories or to avoid rate limiting.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> [state]"
    echo "  owner/repo: The GitHub repository"
    echo "  state: (optional) open, closed, or all. Default: open"
    echo "  Note: GITHUB_TOKEN environment variable can be used for authentication."
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

REPO=$1
STATE=${2:-open}

echo "Fetching $STATE pull requests for $REPO..."

# Fetch PRs from GitHub API
API_URL="https://api.github.com/repos/$REPO/pulls?state=$STATE"

# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps)
if [ -n "${GITHUB_TOKEN:-}" ]; then
    ESCAPED_TOKEN=$(echo "$GITHUB_TOKEN" | sed 's/\\/\\\\/g; s/"/\\"/g')
    PRS=$(printf "header = \"Authorization: Bearer %s\"\n" "$ESCAPED_TOKEN" | curl -s -K- -H "Accept: application/vnd.github.v3+json" "$API_URL")
else
    PRS=$(curl -s -H "Accept: application/vnd.github.v3+json" "$API_URL")
fi

# Check for errors in response
if echo "$PRS" | jq -e '.message?' > /dev/null; then
    MESSAGE=$(echo "$PRS" | jq -r '.message')
    echo "Error from GitHub API: $MESSAGE"
    exit 1
fi

if [ "$PRS" == "[]" ] || [ -z "$PRS" ]; then
    echo "No $STATE pull requests found for $REPO."
    exit 0
fi

# Output as a table
printf "%-10s %-20s %s\n" "NUMBER" "USER" "TITLE"
echo "---------------------------------------------------------"
echo "$PRS" | jq -r '.[] | "\(.number)\t\(.user.login)\t\(.title)"' | while IFS=$'\t' read -r num user title; do
    printf "%-10s %-20s %s\n" "$num" "$user" "$title"
done
