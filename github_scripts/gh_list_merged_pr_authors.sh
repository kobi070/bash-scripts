#!/bin/bash

# Script to list unique authors of merged pull requests in a GitHub repository.
# Useful for generating contribution reports or identifying active developers.
# Usage: ./gh_list_merged_pr_authors.sh <owner/repo> [since_date]
# Example: ./gh_list_merged_pr_authors.sh jules/my-repo 2023-01-01

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> [since_date]"
    echo "  owner/repo: The target GitHub repository (e.g., cli/cli)"
    echo "  since_date: (optional) Only include PRs merged after this date (ISO 8601 format, e.g., 2023-10-27)"
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

if [ "$#" -lt 1 ]; then
    usage
fi

REPO=$1
SINCE=${2:-"1970-01-01"}

echo "Fetching merged PR authors for $REPO since $SINCE..."

# Fetch merged PRs and extract authors
# We use --limit 1000 to get a reasonable history; gh CLI defaults to 30.
gh pr list -R "$REPO" --state merged --limit 1000 --json author,mergedAt | jq -r --arg since "$SINCE" '
  .[] |
  select(.mergedAt >= $since) |
  .author.login
' | sort -u | while read -r author; do
    echo "  - $author"
done

echo "---------------------------------------------------------"
echo "Done."
