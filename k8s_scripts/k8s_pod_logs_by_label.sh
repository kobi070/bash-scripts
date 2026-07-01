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

TAIL_ARGS=()
if [ -n "$TAIL" ]; then
    # Security check: Ensure TAIL is a numeric integer to prevent shell arithmetic injection
    # and to ensure it is a valid value for --tail
    if [[ ! "$TAIL" =~ ^[0-9]+$ ]]; then
        echo "Error: tail_lines must be a positive numeric integer."
        exit 1
    fi
    TAIL_ARGS=("--tail=$TAIL")
fi

echo "Fetching logs for pods with label '$LABEL_SELECTOR' in namespace '$NAMESPACE'..."

# Get all pod names matching the label
PODS=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL_SELECTOR" -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo "No pods found matching label '$LABEL_SELECTOR' in namespace '$NAMESPACE'."
    exit 0
fi

for POD in $PODS; do
    echo "================================================================================"
    echo "Logs for pod: $POD"
    echo "================================================================================"
    kubectl logs -n "$NAMESPACE" "$POD" "${TAIL_ARGS[@]}" || echo "Failed to fetch logs for $POD"
    echo -e "\n"
done
