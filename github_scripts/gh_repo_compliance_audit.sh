#!/bin/bash

# Script to audit GitHub repository settings against security best practices.
# Uses GitHub CLI (gh) to check visibility, branch protection, and other settings.
# Part of the Sentinel philosophy.
# Usage: ./gh_repo_compliance_audit.sh [owner/repo]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [owner/repo]"
    echo "  owner/repo: The target GitHub repository (e.g., jules/my-repo)."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if [ "$#" -ne 1 ]; then
    usage
fi

REPO=$1

# Check for required tools
for tool in gh jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

echo "Auditing repository compliance for: $REPO"

# Fetch repo metadata in one call (Bolt)
REPO_DATA=$(gh repo view "$REPO" --json isPrivate,deleteBranchOnMerge,squashMergeAllowed,rebaseMergeAllowed,defaultBranchRef)

PRIVATE=$(echo "$REPO_DATA" | jq -r '.isPrivate')
DELETE_BRANCH=$(echo "$REPO_DATA" | jq -r '.deleteBranchOnMerge')
DEFAULT_BRANCH=$(echo "$REPO_DATA" | jq -r '.defaultBranchRef.name')

echo "--- Repository Settings ---"
echo "Visibility: $( [ "$PRIVATE" == "true" ] && echo "Private (PASS)" || echo "Public (CHECK REQUIRED)" )"
echo "Auto-delete head branches: $( [ "$DELETE_BRANCH" == "true" ] && echo "Enabled (PASS)" || echo "Disabled (WARNING)" )"
echo "Default Branch: $DEFAULT_BRANCH"

echo -e "\n--- Branch Protection (Default Branch) ---"
# Check if branch protection is enabled by trying to list it
PROTECTION=$(gh api "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --silent 2>&1 || echo "Error: Not protected")

if [[ "$PROTECTION" == *"Not Found"* || "$PROTECTION" == *"Error"* ]]; then
    echo "CRITICAL: Branch protection is NOT enabled for $DEFAULT_BRANCH!"
else
    echo "OK: Branch protection is enabled for $DEFAULT_BRANCH."
fi

echo -e "\nCompliance audit complete."
