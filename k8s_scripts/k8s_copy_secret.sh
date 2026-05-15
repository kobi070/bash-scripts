#!/bin/bash

# Script to copy a Kubernetes secret from one namespace to another.
# It cleans up metadata like resourceVersion, uid, and creationTimestamp to allow for a clean import.
# Usage: ./k8s_copy_secret.sh <secret_name> <source_namespace> <target_namespace>

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <secret_name> <source_namespace> <target_namespace>"
    echo "  secret_name: The name of the secret to copy"
    echo "  source_namespace: The namespace where the secret currently exists"
    echo "  target_namespace: The namespace to copy the secret to"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in kubectl jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

# Input validation
if [ "$#" -ne 3 ]; then
    usage
fi

SECRET_NAME=$1
SOURCE_NS=$2
TARGET_NS=$3

echo "Copying secret '$SECRET_NAME' from '$SOURCE_NS' to '$TARGET_NS'..."

# Check if source secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$SOURCE_NS" &> /dev/null; then
    echo "Error: Secret '$SECRET_NAME' not found in namespace '$SOURCE_NS'."
    exit 1
fi

# Ensure target namespace exists
if ! kubectl get namespace "$TARGET_NS" &> /dev/null; then
    echo "Target namespace '$TARGET_NS' does not exist. Creating it..."
    kubectl create namespace "$TARGET_NS"
fi

# Copy and clean the secret
kubectl get secret "$SECRET_NAME" -n "$SOURCE_NS" -o json | \
    jq 'del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.namespace, .metadata.selfLink, .metadata.ownerReferences)' | \
    kubectl apply -n "$TARGET_NS" -f -

echo "Successfully copied secret '$SECRET_NAME' to '$TARGET_NS'."
