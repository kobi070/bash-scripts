#!/bin/bash

# Script to fetch logs from all pods matching a specific label.
# Useful for debugging issues across a distributed service.
# Usage: ./k8s_pod_logs_by_label.sh <label_selector> [namespace] [tail_lines]
# Example: ./k8s_pod_logs_by_label.sh app=my-service default 100

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <label_selector> [namespace] [tail_lines]"
    echo "  label_selector: Kubernetes label selector (e.g., app=nginx)"
    echo "  namespace: (optional) The namespace to search in. Default: default"
    echo "  tail_lines: (optional) Number of lines to show from the end of logs. Default: all"
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
if [ "$#" -lt 1 ]; then
    usage
fi

LABEL_SELECTOR=$1
NAMESPACE=${2:-default}
TAIL=${3:-""}

TAIL_ARG=""
if [ -n "$TAIL" ]; then
    TAIL_ARG="--tail=$TAIL"
fi

echo "Fetching logs for pods with label '$LABEL_SELECTOR' in namespace '$NAMESPACE'..."

# BOLT Optimization: Use a single kubectl logs call with -l and --prefix=true.
# This reduces the process forks from O(N) to O(1) by avoiding the need to
# first fetch all pod names and then iterate through them sequentially.
# The --prefix=true flag ensures that each log line is prefixed with the pod name.
kubectl logs -n "$NAMESPACE" -l "$LABEL_SELECTOR" --prefix=true $TAIL_ARG || echo "No pods found or failed to fetch logs for '$LABEL_SELECTOR'"

echo -e "\nDone."
