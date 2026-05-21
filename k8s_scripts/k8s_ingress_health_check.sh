#!/bin/bash

# Script to verify that all Ingress hosts in a namespace are resolvable and returning healthy status codes.
# Useful for post-deployment verification of routing and backend health.
# Usage: ./k8s_ingress_health_check.sh [namespace] [expected_status]
# Example: ./k8s_ingress_health_check.sh production 200

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace] [expected_status]"
    echo "  namespace: (optional) The namespace to check. Default: current namespace"
    echo "  expected_status: (optional) Expected HTTP status code. Default: 200"
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

if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

NAMESPACE_ARG=""
if [ "$#" -ge 1 ]; then
    NAMESPACE_ARG="-n $1"
fi

EXPECTED_STATUS="${2:-200}"

echo "Fetching Ingress hosts..."
# Extract hosts from all ingresses in the namespace
HOSTS=$(kubectl get ingress $NAMESPACE_ARG -o json | jq -r '.items[].spec.rules[]?.host' | sort -u)

if [ -z "$HOSTS" ]; then
    echo "No Ingress hosts found in namespace."
    exit 0
fi

echo "Checking health of Ingress hosts (Expecting HTTP $EXPECTED_STATUS)..."
echo "--------------------------------------------------------------------------------"
printf "%-40s %-15s %-15s\n" "HOST" "STATUS CODE" "RESULT"
echo "--------------------------------------------------------------------------------"

FAILED=0
for host in $HOSTS; do
    # Skip empty hosts
    [ -z "$host" ] && continue

    # Perform health check using curl
    # -s: silent
    # -o /dev/null: ignore output body
    # -w: write-out specific format
    # --connect-timeout: limit connection time
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$host" || echo "000")

    if [ "$STATUS_CODE" == "$EXPECTED_STATUS" ]; then
        RESULT="PASS"
    else
        RESULT="FAIL"
        FAILED=$((FAILED + 1))
    fi

    printf "%-40s %-15s %-15s\n" "$host" "$STATUS_CODE" "$RESULT"
done

echo "--------------------------------------------------------------------------------"
if [ "$FAILED" -eq 0 ]; then
    echo "All Ingress hosts are healthy."
    exit 0
else
    echo "Found $FAILED unhealthy Ingress host(s)."
    exit 1
fi
