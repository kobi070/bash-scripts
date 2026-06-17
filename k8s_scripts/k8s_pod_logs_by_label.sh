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

# Bolt optimization: Replace O(N) sequential kubectl logs calls with a single O(1) call
# using label selectors and --prefix (available since K8s 1.17).
# This reduces process forks and API overhead significantly while improving log correlation.

# First, check if any pods match the selector to provide a friendly message
if [[ $(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o name 2>/dev/null | wc -l) -eq 0 ]]; then
    echo "No pods found matching label '$LABEL_SELECTOR' in namespace '$NAMESPACE'."
    exit 0
fi

# Fetch logs for all matching pods in a single operation
kubectl logs -n "$NAMESPACE" -l "$LABEL_SELECTOR" --prefix=true $TAIL_ARG
