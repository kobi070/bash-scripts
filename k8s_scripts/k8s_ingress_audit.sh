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

# Bolt optimization: Consolidate Ingress auditing into a single jq pipeline.
# This reduces process forks from O(N*M) to O(1), where N is Ingress resources and M is rules/paths.
kubectl get ingress $NS_ARG -o json | jq -r '
  .items[] |
  .metadata.namespace as $ns |
  .metadata.name as $name |
  ([.spec.rules[]?.host // "None"] | if length > 0 then join(",") else "None" end) as $hosts |
  (if (.spec.tls | length) > 0 then "YES" else "NO" end) as $tls |
  ([.spec.rules[]?.http.paths[]?.backend.service.name // .spec.backend.service.name // "N/A"] | unique | if length > 0 then join(",") else "N/A" end) as $backends |
  "\($ns)\t\($name)\t\($hosts)\t\($tls)\t\($backends)"
' | while IFS=$'\t' read -r ns name hosts tls backends; do
    printf "%-20s %-30s %-30s %-10s %-20s\n" "$ns" "$name" "$hosts" "$tls" "$backends"
done

echo "------------------------------------------------------------------------------------------------------------------------------------"
