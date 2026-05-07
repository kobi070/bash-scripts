#!/bin/bash
set -euo pipefail

# This script lists all pods that are NOT in 'Running' or 'Succeeded' state across all namespaces.

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl is not installed."
    exit 1
fi

echo "Listing pods with failed or non-running status:"
kubectl get pods --all-namespaces | grep -vE 'Running|Succeeded|STATUS' || echo "No failed pods found."
