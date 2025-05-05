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

minikube kubectl -- --help > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "kubectl command not found. Please install kubectl."
    exit 1
fi

# Check if the namespace already exists
if minikube kubectl -- get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
    echo "Namespace '$NAMESPACE_NAME' already exists."
else
    # Create the namespace
    minikube kubectl -- create namespace "$NAMESPACE_NAME"
    echo "Namespace '$NAMESPACE_NAME' created."
fi

# Apply the label to the namespace
# kubectl label namespace "$NAMESPACE_NAME" "$LABEL_KEY=$LABEL_VALUE" --overwrite
# if [ $? -eq 0 ]; then
#     echo "Label '$LABEL_KEY=$LABEL_VALUE' applied to namespace '$NAMESPACE_NAME'."
# else
#     echo "Failed to apply label to namespace '$NAMESPACE_NAME'."
# fi

# # Check if the label was applied successfully
# if kubectl get namespace "$NAMESPACE_NAME" --show-labels | grep -q "$LABEL_KEY=$LABEL_VALUE"; then
#     echo "Label '$LABEL_KEY=$LABEL_VALUE' is present on namespace '$NAMESPACE_NAME'."
# else
#     echo "Label '$LABEL_KEY=$LABEL_VALUE' is not present on namespace '$NAMESPACE_NAME'."
# fi

# # Check if the namespace is labeled correctly
# if kubectl get namespace "$NAMESPACE_NAME" --show-labels | grep -q "$LABEL_KEY=$LABEL_VALUE"; then
#     echo "Namespace '$NAMESPACE_NAME' is labeled correctly."
# else
#     echo "Namespace '$NAMESPACE_NAME' is not labeled correctly."
# fi
