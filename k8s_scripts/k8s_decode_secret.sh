#!/bin/bash

# Script to decode all keys in a Kubernetes secret.
# Useful for debugging and verifying secret contents.
# Usage: ./k8s_decode_secret.sh <secret_name> [namespace] [--raw]
# Example: ./k8s_decode_secret.sh my-secret my-namespace

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <secret_name> [namespace] [--raw]"
    echo "  secret_name: The name of the Kubernetes secret"
    echo "  namespace: (optional) The namespace of the secret. Default: default"
    echo "  --raw: (optional) Force output of unredacted secrets even in non-interactive terminals"
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
NAMESPACE="default"
RAW_MODE=false

# Simple argument parsing
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --raw)
            RAW_MODE=true
            shift
            ;;
        *)
            NAMESPACE=$1
            shift
            ;;
    esac
done

echo "Decoding secret $SECRET_NAME in namespace $NAMESPACE..."

# Fetch secret data once to avoid redundant calls
SECRET_DATA=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o json | jq -r '.data')

# Check if the terminal is interactive or raw mode is enabled
if [ -t 1 ] || [ "$RAW_MODE" = true ]; then
    # Decode and print each data entry
    echo "$SECRET_DATA" | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
else
    echo "WARNING: Non-interactive terminal detected. Secrets redacted to prevent leakage in logs."
    echo "To view decoded secrets, run this script in an interactive terminal or use the --raw flag:"
    echo "Example: $0 $SECRET_NAME $NAMESPACE --raw"
    echo ""
    echo "Alternatively, use kubectl directly:"
    echo "kubectl get secret \"$SECRET_NAME\" -n \"$NAMESPACE\" -o json | jq -r '.data | to_entries[] | \"\\(.key): \\(.value | @base64d)\"'"
    echo ""

    # Show keys with redacted values
    echo "$SECRET_DATA" | jq -r 'to_entries[] | "\(.key): [REDACTED]"'
fi
