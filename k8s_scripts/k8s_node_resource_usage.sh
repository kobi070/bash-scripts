#!/bin/bash

# Script to summarize CPU and Memory usage across all nodes in a Kubernetes cluster.
# Useful for a quick health check of the cluster's capacity.
# Usage: ./k8s_node_resource_usage.sh
# Example: ./k8s_node_resource_usage.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0"
    echo "  No arguments required."
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

echo "Fetching resource usage for all nodes..."

# Check if metrics-server is likely installed
if ! kubectl top nodes &> /dev/null; then
    echo "Error: 'kubectl top nodes' failed. Metrics-server might not be installed or reachable."
    exit 1
fi

echo "--------------------------------------------------------------------------------"
kubectl top nodes
echo "--------------------------------------------------------------------------------"

# Get more detailed information about node capacity vs allocatable
echo "Node Capacity and Allocatable Resources:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU-CAP:.status.capacity.cpu,CPU-ALLOC:.status.allocatable.cpu,MEM-CAP:.status.capacity.memory,MEM-ALLOC:.status.allocatable.memory
