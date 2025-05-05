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

minikube kubectl -- --help >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "kubectl command not found. Please install kubectl."
    exit 1
fi

# Check if the namespace already exists
if minikube kubectl -- get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
    # Delete the namespace
    minikube kubectl -- delete namespace "$NAMESPACE_NAME"
    echo "Namespace '$NAMESPACE_NAME' deleted."
else
    echo "Namespace '$NAMESPACE_NAME' does not exist."
fi
