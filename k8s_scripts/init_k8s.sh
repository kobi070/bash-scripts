#!/bin/bash
set -e 

# Check if kubectl is installed
if ! [ -x "$(command -v kubectl)" ]; then
    echo "kubectl is not installed. Please install kubectl."
    exit 1
fi

# Check if minikube is installed
if ! [ -x "$(command -v minikube)" ]; then
    echo "minikube is not installed. Please install minikube."
    exit 1
fi

echo "✅ Minikube is installed successfully !"