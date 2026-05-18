#!/bin/bash

# Script to display the diff between Git and Cluster state for a specified ArgoCD application.
# Useful for reviewing changes before syncing.
# Usage: ./argocd_app_diff.sh <app_name> [options]
# Example: ./argocd_app_diff.sh my-app --revision feature/test

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <app_name> [options]"
    echo "  app_name: Name of the ArgoCD application"
    echo "  options: Additional options for 'argocd app diff' (e.g., --revision, --refresh)"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
    usage
fi

# Check for required tools
if ! command -v argocd &> /dev/null; then
    echo "Error: ArgoCD CLI (argocd) is not installed or not in PATH."
    exit 1
fi

APP_NAME=$1
shift # Remaining arguments are passed to argocd app diff

echo "Comparing Git and Cluster state for ArgoCD app: $APP_NAME..."

# Check if authenticated or if ARGOCD_AUTH_TOKEN is set
# If not authenticated, the command will fail with a helpful message
if ! argocd account get-user-info &> /dev/null; then
    if [ -z "${ARGOCD_AUTH_TOKEN:-}" ] && [ -z "${ARGOCD_OPTS:-}" ]; then
        echo "Warning: Not logged into ArgoCD. Ensure ARGOCD_AUTH_TOKEN or ARGOCD_OPTS is set, or run 'argocd login'."
    fi
fi

# Run diff
# Note: 'argocd app diff' returns exit code 1 if there is a diff, and 0 if no diff.
# This can be confusing with 'set -e'. We handle this.
set +e
DIFF_OUTPUT=$(argocd app diff "$APP_NAME" "$@" 2>&1)
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -eq 0 ]; then
    echo "OK: No differences found between Git and Cluster."
    exit 0
elif [ $EXIT_CODE -eq 1 ]; then
    echo "Differences found:"
    echo "--------------------------------------------------------------------------------"
    echo "$DIFF_OUTPUT"
    echo "--------------------------------------------------------------------------------"
    exit 0 # We consider "found diff" as success for this script
else
    echo "Error: 'argocd app diff' failed with exit code $EXIT_CODE"
    echo "$DIFF_OUTPUT"
    exit $EXIT_CODE
fi
