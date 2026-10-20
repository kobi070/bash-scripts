#!/bin/bash

# Script to scale a Kubernetes deployment up or down.
# Usage: ./k8s_scale_deployment.sh [namespace] [deployment] [replicas]
# Example: ./k8s_scale_deployment.sh default my-app 5

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace] [deployment] [replicas]"
    echo "  namespace: (optional) The namespace of the deployment. Default: default"
    echo "  deployment: The deployment to scale."
    echo "  replicas: The number of replicas to scale the deployment to."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in kubectl; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

# Parse arguments
NAMESPACE="${1:-default}"
DEPLOYMENT="${2:-}"
REPLICAS="${3:-}"

# Validate required arguments
if [[ -z "$DEPLOYMENT" || -z "$REPLICAS" ]]; then
    echo "Error: Deployment and replicas must be specified."
    usage
fi

# Validate replicas is a non-negative integer
if ! [[ "$REPLICAS" =~ ^[0-9]+$ ]]; then
    echo "Error: Replicas must be a non-negative integer."
    exit 1
fi

# Check namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Error: Namespace '$NAMESPACE' not found."
    exit 1
fi

# Check deployment exists in namespace
if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" &> /dev/null; then
    echo "Error: Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'."
    exit 1
fi

# Get current replica count
CURRENT_REPLICAS=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

if [[ "$REPLICAS" -eq "$CURRENT_REPLICAS" ]]; then
    echo "Deployment '$DEPLOYMENT' in namespace '$NAMESPACE' is already at $REPLICAS replicas. No action taken."
    exit 0
elif [[ "$REPLICAS" -gt "$CURRENT_REPLICAS" ]]; then
    echo "Scaling UP '$DEPLOYMENT' in namespace '$NAMESPACE': $CURRENT_REPLICAS -> $REPLICAS"
else
    echo "Scaling DOWN '$DEPLOYMENT' in namespace '$NAMESPACE': $CURRENT_REPLICAS -> $REPLICAS"
fi

# Scale the deployment
kubectl scale deployment "$DEPLOYMENT" --replicas="$REPLICAS" -n "$NAMESPACE"

# Wait for rollout to reflect the desired replica count
kubectl rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s