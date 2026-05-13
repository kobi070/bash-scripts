#!/bin/bash

# Script to list all collaborators of a GitHub repository using the GitHub API.
# Useful for access audits and security reviews.
# Usage: ./gh_list_collaborators.sh <owner> <repo>
# Example: ./gh_list_collaborators.sh octocat hello-world

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner> <repo>"
    echo "  owner: The GitHub user or organization that owns the repository"
    echo "  repo: The name of the repository"
    echo "Note: GITHUB_TOKEN environment variable must be set for private repositories or to avoid rate limiting."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Input validation
if [ "$#" -ne 2 ]; then
    usage
fi

OWNER=$1
REPO=$2

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

AUTH_ARGS=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_ARGS=(-H "Authorization: token $GITHUB_TOKEN")
fi

echo "Fetching collaborators for $OWNER/$REPO..."

# Fetch collaborators using GitHub API
# Handles pagination (basic - up to 100 collaborators)
API_URL="https://api.github.com/repos/$OWNER/$REPO/collaborators?per_page=100"

RESPONSE=$(curl -s "${AUTH_ARGS[@]}" -H "Accept: application/vnd.github+json" "$API_URL")

# Check for errors in response
if echo "$RESPONSE" | jq -e '.message' > /dev/null; then
    MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
    echo "Error from GitHub API: $MESSAGE"
    exit 1
fi

echo "Collaborators found:"
echo "LOGIN | PERMISSIONS"
echo "-------------------"
echo "$RESPONSE" | jq -r '.[] | "\(.login) | \(.permissions | to_entries | map(select(.value == true) | .key) | join(","))"' | column -t -s '|'
