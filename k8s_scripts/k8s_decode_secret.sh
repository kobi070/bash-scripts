#!/bin/bash

# Script to decode all keys in a Kubernetes secret.
# Useful for debugging and verifying secret contents.
# Usage: ./k8s_decode_secret.sh <secret_name> [namespace]
# Example: ./k8s_decode_secret.sh my-secret my-namespace

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <secret_name> [namespace]"
    echo "  secret_name: The name of the Kubernetes secret"
    echo "  namespace: (optional) The namespace of the secret. Default: default"
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

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

SECRET_NAME=$1
NAMESPACE=${2:-default}

echo "Decoding secret $SECRET_NAME in namespace $NAMESPACE..."

# Get the secret in JSON format and decode each data entry
kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o json | jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
