#!/bin/bash

# Script to audit branch protection status for a GitHub repository.
# Specifically checks the default branch unless another branch is specified.
# Usage: ./gh_branch_protection_audit.sh <owner/repo> [branch]
# Example: ./gh_branch_protection_audit.sh my-org/my-repo main

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> [branch]"
    echo "  owner/repo: The target GitHub repository."
    echo "  branch: (optional) The branch to check. Default: repo default branch"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
    usage
fi

# Check for required tools
for tool in gh jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

REPO=$1
BRANCH=${2:-}

# If branch is not specified, get the default branch
if [[ -z "$BRANCH" ]]; then
    echo "Fetching default branch for $REPO..."
    BRANCH=$(gh repo view "$REPO" --json defaultBranchRef --jq '.defaultBranchRef.name')
fi

echo "Auditing branch protection for $REPO:$BRANCH..."

# Fetch branch protection rules
# gh api will return 404 if no protection rules are set
PROTECTION_JSON=$(gh api "repos/$REPO/branches/$BRANCH/protection" 2>/dev/null || echo "NOT_FOUND")

if [[ "$PROTECTION_JSON" == "NOT_FOUND" ]]; then
    echo "WARNING: Branch '$BRANCH' has NO protection rules enabled."
    exit 0
fi

# Extract key protection rules
ENFORCE_ADMINS=$(echo "$PROTECTION_JSON" | jq -r '.enforce_admins.enabled // false')
PR_REQUIRED=$(echo "$PROTECTION_JSON" | jq -r '.required_pull_request_reviews != null')
REQUIRED_CHECKS=$(echo "$PROTECTION_JSON" | jq -r '.required_status_checks != null')
LINEAR_HISTORY=$(echo "$PROTECTION_JSON" | jq -r '.required_linear_history.enabled // false')

printf "Protection Summary for %s:\n" "$BRANCH"
printf "%s\n" "----------------------------------------"
printf "%-30s : %s\n" "Enforce Admins" "$ENFORCE_ADMINS"
printf "%-30s : %s\n" "PR Required" "$PR_REQUIRED"
printf "%-30s : %s\n" "Status Checks Required" "$REQUIRED_CHECKS"
printf "%-30s : %s\n" "Require Linear History" "$LINEAR_HISTORY"

if [[ "$PR_REQUIRED" == "true" ]]; then
    APPROVERS=$(echo "$PROTECTION_JSON" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
    printf "%-30s : %s\n" "Required Approvals" "$APPROVERS"
fi
