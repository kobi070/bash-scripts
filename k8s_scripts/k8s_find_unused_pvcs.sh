#!/bin/bash

# Script to identify PersistentVolumeClaims (PVCs) that are not currently used by any Pods.
# Useful for identifying resources that can be cleaned up to save costs.
# Usage: ./k8s_find_unused_pvcs.sh [namespace]
# Example: ./k8s_find_unused_pvcs.sh production

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace]"
    echo "  namespace: (optional) The namespace to check. Default: all-namespaces"
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

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

NAMESPACE_ARG="--all-namespaces"
if [ "$#" -ge 1 ] && [ "$1" != "all" ]; then
    NAMESPACE_ARG="-n $1"
fi

echo "Searching for unused PVCs..."

# Get all PVCs in the given scope
ALL_PVCS=$(kubectl get pvc $NAMESPACE_ARG -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"')

# Get all PVCs currently mounted by Pods
USED_PVCS=$(kubectl get pods $NAMESPACE_ARG -o json | jq -r '.items[].spec | select(.volumes != null) | .volumes[] | select(.persistentVolumeClaim != null) | .persistentVolumeClaim.claimName' | sort -u)

# Note: The above USED_PVCS might not have namespace info if we just get claimName.
# Let's improve it to include namespace for accurate matching when --all-namespaces is used.
USED_PVCS_WITH_NS=$(kubectl get pods $NAMESPACE_ARG -o json | jq -r '
  .items[] as $pod |
  $pod.spec | select(.volumes != null) | .volumes[] | select(.persistentVolumeClaim != null) |
  "\($pod.metadata.namespace)/\(.persistentVolumeClaim.claimName)"
' | sort -u)

# Identify unused PVCs by comparing the lists
if [ -z "$USED_PVCS_WITH_NS" ]; then
    # If no PVCs are used, all found PVCs are unused
    UNUSED_PVCS="$ALL_PVCS"
else
    # Optimized: use grep -xvFf to find lines in ALL_PVCS that are not in USED_PVCS_WITH_NS.
    # -x ensures exact line matching to avoid substring issues.
    # This replaces an O(N*M) loop with nested process forks with a single, efficient O(N+M) process.
    UNUSED_PVCS=$(grep -xvFf <(echo "$USED_PVCS_WITH_NS") <(echo "$ALL_PVCS") || true)
fi

if [ -z "$UNUSED_PVCS" ]; then
    echo "No unused PVCs found."
else
    echo "NAMESPACE/NAME"
    echo "$UNUSED_PVCS"
fi
