#!/bin/bash

# Script to verify that all pods in a namespace have CPU and Memory limits defined.
# Useful for ensuring cluster stability and preventing resource exhaustion.
# Usage: ./k8s_check_resource_limits.sh [namespace]
# Example: ./k8s_check_resource_limits.sh production

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

echo "Checking for pods without resource limits..."

# Get pods and their container resource limits
# Filter for pods that have at least one container without cpu or memory limit
PODS_WITHOUT_LIMITS=$(kubectl get pods $NAMESPACE_ARG -o json | jq -r '
  .items[] |
  select(
    .status.phase == "Running" and
    (.spec.containers[] | select(.resources.limits.cpu == null or .resources.limits.memory == null))
  ) |
  "\(.metadata.namespace) \(.metadata.name)"
' | sort -u)

if [ -z "$PODS_WITHOUT_LIMITS" ]; then
    echo "OK: All running pods have CPU and Memory limits defined."
    exit 0
else
    echo "WARNING: The following running pods have containers missing CPU or Memory limits:"
    echo "NAMESPACE POD"
    echo "$PODS_WITHOUT_LIMITS" | column -t
    exit 1
fi
