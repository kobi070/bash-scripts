#!/bin/bash
set -euo pipefail

# This script lists all applications managed by ArgoCD.

if ! command -v argocd >/dev/null 2>&1; then
    echo "Error: ArgoCD CLI (argocd) is not installed."
    exit 1
fi

# Basic check if user is logged in (this might vary depending on environment)
if ! argocd account get-user-info >/dev/null 2>&1; then
    echo "Warning: You might not be logged into ArgoCD. Please run 'argocd login'."
fi

echo "Listing ArgoCD applications:"
argocd app list
