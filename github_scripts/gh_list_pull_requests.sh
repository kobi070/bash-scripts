#!/bin/bash

# Script to list open pull requests for a GitHub repository using the API.
# Useful for automation tasks that need to track active PRs.
# Usage: ./gh_list_pull_requests.sh <owner/repo> [state]
# Example: ./gh_list_pull_requests.sh kubernetes/kubernetes open

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> [state]"
    echo "  owner/repo: The GitHub repository"
    echo "  state: (optional) open, closed, or all. Default: open"
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
PRS=$(curl -s "https://api.github.com/repos/$REPO/pulls?state=$STATE")

if [ "$PRS" == "[]" ] || [ -z "$PRS" ]; then
    echo "No $STATE pull requests found for $REPO."
    exit 0
fi

# Output as a table
echo "$PRS" | jq -r '.[] | "\(.number)\t\(.user.login)\t\(.title)"' | column -t -s $'\t' -N NUMBER,USER,TITLE
