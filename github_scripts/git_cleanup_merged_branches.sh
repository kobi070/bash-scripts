#!/bin/bash
# git_cleanup_merged_branches.sh - Deletes local branches that have been merged into the default branch.

set -euo pipefail

usage() {
    echo "Usage: $0 [-d <default_branch>] [-f]"
    echo "  -d <default_branch>  The default branch to compare against (defaults to 'main')"
    echo "  -f                   Force delete without prompting (non-interactive)"
    echo "  -h, --help           Display this help message"
    exit 1
}

DEFAULT_BRANCH="main"
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--default)
            DEFAULT_BRANCH="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Verify it's a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not a git repository."
    exit 1
fi

# Ensure we are on the default branch or it exists
if ! git rev-parse --verify "$DEFAULT_BRANCH" &>/dev/null; then
    echo "Error: Default branch '$DEFAULT_BRANCH' does not exist."
    exit 1
fi

echo "Fetching latest changes and pruning remote branches..."
git fetch --prune

echo "Identifying merged branches relative to '$DEFAULT_BRANCH'..."

# Get list of merged branches, excluding the current branch and the default branch
MERGED_BRANCHES=$(git branch --merged "$DEFAULT_BRANCH" | grep -v "^\*" | grep -v "^  $DEFAULT_BRANCH$" || true)

if [[ -z "$MERGED_BRANCHES" ]]; then
    echo "No merged branches to clean up."
    exit 0
fi

echo "The following local branches have been merged into $DEFAULT_BRANCH:"
echo "$MERGED_BRANCHES"

if [ "$FORCE" = true ]; then
    echo "Force deleting merged branches..."
    echo "$MERGED_BRANCHES" | xargs -n 1 git branch -d
else
    read -p "Do you want to delete these branches? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$MERGED_BRANCHES" | xargs -n 1 git branch -d
    else
        echo "Cleanup cancelled."
    fi
fi
