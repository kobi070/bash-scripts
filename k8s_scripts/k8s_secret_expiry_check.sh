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

echo "Checking for TLS secrets expiring within $THRESHOLD_DAYS days..."
printf "%-30s %-30s %-20s %-10s\n" "NAMESPACE" "SECRET" "EXPIRY DATE" "DAYS LEFT"
echo "----------------------------------------------------------------------------------------------------"

# Bolt optimization: Consolidate data extraction and processing to reduce process forks from O(7N) to O(2N).
# 1. Use a single jq pass to extract necessary fields.
# 2. Use openssl -dateopt iso_8601 for portable, parseable date output.
# 3. Use a final jq pass for date arithmetic and filtering, eliminating per-iteration date forks.

# shellcheck disable=SC2086
kubectl get secrets $NAMESPACE_ARG --field-selector type=kubernetes.io/tls -o json | \
jq -r '.items[] | "\(.metadata.namespace)\t\(.metadata.name)\t\(.data["tls.crt"] // "")"' | \
while IFS=$'\t' read -r ns name cert_b64; do
    if [[ -z "$cert_b64" ]]; then continue; fi

    # Get expiry in standard OpenSSL format: notAfter=Jun  9 04:30:34 2026 GMT
    # We use the standard format to ensure compatibility with older OpenSSL versions (< 3.0).
    EXPIRY_RAW=$(echo "$cert_b64" | base64 -d | openssl x509 -enddate -noout 2>/dev/null || echo "notAfter=Jan  1 00:00:00 1970 GMT")
    EXPIRY=${EXPIRY_RAW#notAfter=}

    printf "%s\t%s\t%s\n" "$ns" "$name" "$EXPIRY"
done | \
jq -R -r --argjson threshold "$THRESHOLD_DAYS" --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '
  ($now | fromdateiso8601) as $now_sec |
  split("\t") |
  {ns: .[0], name: .[1], expiry: .[2]} |
  (.expiry | strptime("%b %e %H:%M:%S %Y %Z") | mktime) as $exp_sec |
  (($exp_sec - $now_sec) / 86400 | floor) as $days_left |
  select($days_left < $threshold) |
  "\(.ns)\t\(.name)\t\(.expiry)\t\($days_left)"
' | while IFS=$'\t' read -r ns name exp days; do
    printf "%-30s %-30s %-20s %-10s\n" "$ns" "$name" "$exp" "$days"
done
