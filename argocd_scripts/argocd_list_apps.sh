#!/bin/bash

# Script to list all ArgoCD applications with their health and sync status.
# Useful for a quick overview of the status of all deployments managed by ArgoCD.
# Usage: ./argocd_list_apps.sh
# Example: ./argocd_list_apps.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0"
    echo "  No arguments required."
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

echo "Fetching ArgoCD applications status..."

# List apps with specific columns
argocd app list -o wide
