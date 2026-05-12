#!/bin/bash

# Script to identify PersistentVolumeClaims (PVCs) that are not currently mounted by any Pod.
# This helps in identifying potentially unused resources for cleanup and cost optimization.
# Usage: ./k8s_find_unused_pvcs.sh [namespace]
# Example: ./k8s_find_unused_pvcs.sh default

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace]"
    echo "  namespace: (optional) The Kubernetes namespace to scan. Default: current namespace"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH."
    exit 1
fi

NAMESPACE=${1:-$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default")}
if [ -z "$NAMESPACE" ]; then NAMESPACE="default"; fi

echo "Scanning namespace: $NAMESPACE for unused PVCs..."

# Get all PVCs in the namespace
ALL_PVCS=$(kubectl get pvc -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

if [ -z "$ALL_PVCS" ]; then
    echo "No PVCs found in namespace $NAMESPACE."
    exit 0
fi

# Get all PVCs currently mounted by Pods in the namespace
MOUNTED_PVCS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.volumes[*].persistentVolumeClaim.claimName}' | tr ' ' '\n' | sort -u)

echo "------------------------------------------------"
echo "Unused PVCs in namespace '$NAMESPACE':"
echo "------------------------------------------------"

FOUND_UNUSED=false
for pvc in $ALL_PVCS; do
    if ! echo "$MOUNTED_PVCS" | grep -q "^$pvc$"; then
        echo "- $pvc"
        FOUND_UNUSED=true
    fi
done

if [ "$FOUND_UNUSED" = false ]; then
    echo "No unused PVCs found."
fi
echo "------------------------------------------------"
