#!/bin/bash

# Script to wait for a Kubernetes resource to reach a ready state.
# Useful for CI/CD pipelines to ensure deployments are ready before proceeding.
# Usage: ./k8s_wait_ready.sh <resource_type> <resource_name> [namespace] [timeout]
# Example: ./k8s_wait_ready.sh deployment my-app my-namespace 300s

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <resource_type> <resource_name> [namespace] [timeout]"
    echo "  resource_type: deployment, statefulset, or daemonset"
    echo "  resource_name: name of the resource"
    echo "  namespace: (optional) kubernetes namespace"
    echo "  timeout: (optional) timeout duration (e.g., 300s). Default: 300s"
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

# Input validation
if [ "$#" -lt 2 ]; then
    usage
fi

RESOURCE_TYPE=$1
RESOURCE_NAME=$2
NAMESPACE=${3:-default}
TIMEOUT=${4:-300s}

# Validate resource type
case "$RESOURCE_TYPE" in
    deployment|statefulset|daemonset)
        ;;
    *)
        echo "Error: Unsupported resource type '$RESOURCE_TYPE'. Use 'deployment', 'statefulset', or 'daemonset'."
        exit 1
        ;;
esac

echo "Waiting for $RESOURCE_TYPE/$RESOURCE_NAME in namespace $NAMESPACE to be ready (timeout: $TIMEOUT)..."

# Use kubectl rollout status for wait-and-poll logic
if kubectl rollout status "$RESOURCE_TYPE/$RESOURCE_NAME" -n "$NAMESPACE" --timeout="$TIMEOUT"; then
    echo "Resource $RESOURCE_TYPE/$RESOURCE_NAME is ready."
    exit 0
else
    echo "Error: Resource $RESOURCE_TYPE/$RESOURCE_NAME failed to reach ready state within $TIMEOUT."
    exit 1
fi
