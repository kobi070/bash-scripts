#!/bin/bash

# Script to identify expiring TLS secrets in a Kubernetes cluster.
# Usage: ./k8s_secret_expiry_check.sh [namespace] [days_threshold]
# Example: ./k8s_secret_expiry_check.sh default 30

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace] [days_threshold]"
    echo "  namespace: (optional) The namespace to check. Default: all-namespaces"
    echo "  days_threshold: (optional) Report secrets expiring within this many days. Default: 30"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in kubectl openssl jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

NAMESPACE_ARG="--all-namespaces"
if [ "$#" -ge 1 ] && [ "$1" != "all" ]; then
    NAMESPACE_ARG="-n $1"
fi

THRESHOLD_DAYS=${2:-30}

# Security check: Ensure THRESHOLD_DAYS is a numeric integer to prevent shell arithmetic injection
if [[ ! "$THRESHOLD_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: THRESHOLD_DAYS must be a positive numeric integer."
    exit 1
fi

CURRENT_SEC=$(date +%s)
THRESHOLD_SEC=$((THRESHOLD_DAYS * 86400))

echo "Checking for TLS secrets expiring within $THRESHOLD_DAYS days..."
printf "%-30s %-30s %-20s %-10s\n" "NAMESPACE" "SECRET" "EXPIRY DATE" "DAYS LEFT"
echo "----------------------------------------------------------------------------------------------------"

# Get TLS secrets
SECRETS_JSON=$(kubectl get secrets $NAMESPACE_ARG --field-selector type=kubernetes.io/tls -o json)

# Process each secret
echo "$SECRETS_JSON" | jq -c '.items[]' | while read -r item; do
    NS=$(echo "$item" | jq -r '.metadata.namespace')
    NAME=$(echo "$item" | jq -r '.metadata.name')

    # Extract cert data
    CERT_BASE64=$(echo "$item" | jq -r '.data["tls.crt"] // empty')

    if [ -z "$CERT_BASE64" ]; then
        continue
    fi

    # Get expiry date using openssl
    EXPIRY_STR=$(echo "$CERT_BASE64" | base64 -d | openssl x509 -enddate -noout | cut -d= -f2)

    # Convert expiry date to seconds since epoch
    # Note: date -d is GNU specific, for BSD/macOS it would be date -j -f
    # We will try to be portable but prioritize common Linux environments
    if date --version >/dev/null 2>&1; then
        # GNU Date
        EXPIRY_SEC=$(date -d "$EXPIRY_STR" +%s)
    else
        # BSD Date (macOS)
        EXPIRY_SEC=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY_STR" +%s)
    fi

    DIFF_SEC=$((EXPIRY_SEC - CURRENT_SEC))
    DIFF_DAYS=$((DIFF_SEC / 86400))

    if [ "$DIFF_SEC" -lt "$THRESHOLD_SEC" ]; then
        printf "%-30s %-30s %-20s %-10s\n" "$NS" "$NAME" "$EXPIRY_STR" "$DIFF_DAYS"
    fi
done
