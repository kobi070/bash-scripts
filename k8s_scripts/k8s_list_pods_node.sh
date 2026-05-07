#!/bin/bash
set -euo pipefail

# This script lists all pods running on a specific Kubernetes node across all namespaces.

usage() {
    echo "Usage: $0 <node_name>"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

node_name=$1

# Check if kubectl is installed
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl is not installed."
    exit 1
fi

echo "Listing pods on node: $node_name"
kubectl get pods --all-namespaces --field-selector spec.nodeName="$node_name"
