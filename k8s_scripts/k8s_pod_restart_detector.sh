#!/bin/bash

# Script to identify pods in a Kubernetes namespace that have been restarting frequently.
# Useful for identifying unstable services in a cluster.
# Usage: ./k8s_pod_restart_detector.sh [namespace] [restart_threshold]
# Example: ./k8s_pod_restart_detector.sh default 5

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace] [restart_threshold]"
    echo "  namespace: (optional) The namespace to check. Default: all-namespaces"
    echo "  restart_threshold: (optional) Minimum restarts to report. Default: 1"
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

THRESHOLD=${2:-1}

# Security check: Ensure THRESHOLD is a numeric integer to prevent shell arithmetic injection
if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: THRESHOLD must be a positive numeric integer."
    exit 1
fi

echo "Scanning for pods with at least $THRESHOLD restarts..."

# Get pod restart counts using kubectl and jq
# Output format: NAMESPACE POD RESTARTS
kubectl get pods $NAMESPACE_ARG -o json | jq -r --argjson threshold "$THRESHOLD" '
  .items[] |
  {
    namespace: .metadata.namespace,
    name: .metadata.name,
    restarts: ([.status.containerStatuses[]?.restartCount] | add // 0)
  } |
  select(.restarts >= $threshold) |
  "\(.namespace) \(.name) \(.restarts)"
' | column -t -N NAMESPACE,POD,RESTARTS || echo "No pods found exceeding threshold."
