#!/bin/bash

# Script to trigger an ArgoCD application sync and wait for it to be Healthy and Synced.
# Useful for CI/CD pipelines to ensure continuous delivery is completed.
# Usage: ./argocd_app_sync.sh <app_name> [timeout]
# Example: ./argocd_app_sync.sh my-application 600

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <app_name> [timeout]"
    echo "  app_name: name of the ArgoCD application"
    echo "  timeout: (optional) timeout in seconds. Default: 300"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v argocd &> /dev/null; then
    echo "Error: argocd CLI is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

APP_NAME=$1
TIMEOUT=${2:-300}

# Security check: Ensure TIMEOUT is a numeric integer to prevent shell arithmetic injection
if [[ ! "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    echo "Error: timeout must be a positive numeric integer."
    exit 1
fi

echo "Syncing ArgoCD application: $APP_NAME..."

# Trigger sync
if ! argocd app sync "$APP_NAME" --async; then
    echo "Error: Failed to trigger sync for application $APP_NAME."
    exit 1
fi

echo "Waiting for application $APP_NAME to be Healthy and Synced (timeout: ${TIMEOUT}s)..."

# Wait for healthy and synced status
if argocd app wait "$APP_NAME" --health --sync --timeout "$TIMEOUT"; then
    echo "Success: Application $APP_NAME is Healthy and Synced."
    exit 0
else
    echo "Error: Application $APP_NAME failed to reach Healthy/Synced state within ${TIMEOUT}s."
    exit 1
fi
