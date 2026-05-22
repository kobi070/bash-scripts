#!/bin/bash

# jf_list_empty_repos.sh - Identifies repositories in JFrog Artifactory with zero artifacts.
# Useful for cleaning up unused or abandoned repositories.
# Part of the DevOps Automation Hub.

set -euo pipefail

usage() {
    echo "Usage: $0 [repo_type]"
    echo "  repo_type: (optional) Filter by repository type (e.g., local, remote, virtual). Default: local"
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

REPO_TYPE=${1:-local}

# Verify dependencies
if ! command -v jf &> /dev/null; then
    echo "Error: JFrog CLI (jf) is not installed."
    exit 1
fi

echo "Searching for empty $REPO_TYPE repositories..."
echo "--------------------------------------------------------------------------------"
printf "%-30s %-15s %-15s\n" "REPOSITORY" "TYPE" "ARTIFACT COUNT"
echo "--------------------------------------------------------------------------------"

# Fetch repositories of the specified type
# We use 'jf rt repo-list' to get the names
REPOS=$(jf rt repo-list --server-id=default --format=json 2>/dev/null | jq -r --arg TYPE "$REPO_TYPE" '.[] | select(.type == $TYPE) | .key')

if [ -z "$REPOS" ]; then
    echo "No repositories of type '$REPO_TYPE' found."
    exit 0
fi

for repo in $REPOS; do
    # Use AQL (Artifactory Query Language) via JFrog CLI to count items in the repo
    # This is more efficient than a full list
    COUNT=$(jf rt s --spec-vars "repo=$repo" --spec <(echo '{"queries": [{"aql": {"items.find": {"repo": "((repo))"}}}]}') --count 2>/dev/null || echo "0")

    if [ "$COUNT" -eq 0 ]; then
        printf "%-30s %-15s %-15s\n" "$repo" "$REPO_TYPE" "0"
    fi
done

echo "--------------------------------------------------------------------------------"
