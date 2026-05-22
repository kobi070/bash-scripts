#!/bin/bash

# k8s_ingress_audit.sh - Summarizes Ingress resources across all namespaces.
# Provides visibility into exposed hosts, paths, and TLS status.
# Part of the DevOps Automation Hub.

set -euo pipefail

usage() {
    echo "Usage: $0 [namespace]"
    echo "  namespace: (optional) Specific namespace to audit. Defaults to all namespaces."
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Verify dependencies
for tool in kubectl jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

NS_ARG="--all-namespaces"
if [ "$#" -ge 1 ]; then
    NS_ARG="-n $1"
fi

echo "Auditing Ingress resources..."
printf "%-20s %-30s %-30s %-10s %-20s\n" "NAMESPACE" "NAME" "HOSTS" "TLS" "BACKENDS"
echo "------------------------------------------------------------------------------------------------------------------------------------"

# Fetch Ingress data
INGRESS_DATA=$(kubectl get ingress $NS_ARG -o json)

echo "$INGRESS_DATA" | jq -c '.items[]' | while read -r ingress; do
    NAMESPACE=$(echo "$ingress" | jq -r '.metadata.namespace')
    NAME=$(echo "$ingress" | jq -r '.metadata.name')

    # Extract Hosts
    HOSTS=$(echo "$ingress" | jq -r '.spec.rules[]?.host // "None"' | paste -sd "," -)
    [ -z "$HOSTS" ] && HOSTS="None"

    # Check TLS
    TLS_COUNT=$(echo "$ingress" | jq -r '.spec.tls | length')
    TLS_STATUS=$( [ "$TLS_COUNT" -gt 0 ] && echo "YES" || echo "NO" )

    # Extract Backends (Services)
    # Different versions of ingress (v1beta1 vs v1) have slightly different structures.
    # This attempt covers v1 primarily.
    BACKENDS=$(echo "$ingress" | jq -r '.spec.rules[]?.http.paths[]?.backend.service.name // .spec.backend.service.name // "N/A"' | sort -u | paste -sd "," -)
    [ -z "$BACKENDS" ] && BACKENDS="N/A"

    printf "%-20s %-30s %-30s %-10s %-20s\n" "$NAMESPACE" "$NAME" "$HOSTS" "$TLS_STATUS" "$BACKENDS"
done

echo "------------------------------------------------------------------------------------------------------------------------------------"
