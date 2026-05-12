#!/bin/bash

# This script creates a Kubernetes namespace and applies a label to it.
# Usage: ./k8s_create_ns.sh <namespace_name> <label_key> <label_value>
# Usage: ./k8s_create_ns.sh <namespace_name>
# Example: ./k8s_create_ns.sh my-namespace env production
# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <namespace_name>"
    exit 1
fi
# Assign arguments to variables
NAMESPACE_NAME=$1

# Verify kubectl/minikube existence
if ! command -v kubectl &> /dev/null && ! command -v minikube &> /dev/null; then
    echo "Error: kubectl or minikube not found. Please install one of them."
    exit 1
fi

# Use kubectl if available, otherwise fallback to minikube kubectl
KUBECTL_BIN="kubectl"
if ! command -v kubectl &> /dev/null; then
    KUBECTL_BIN="minikube kubectl --"
fi

# Check if the namespace already exists
if $KUBECTL_BIN get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
    # Delete the namespace
    $KUBECTL_BIN delete namespace "$NAMESPACE_NAME"
    echo "Namespace '$NAMESPACE_NAME' deleted."
else
    echo "Namespace '$NAMESPACE_NAME' does not exist."
fi
