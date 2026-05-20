#!/bin/bash

# Script to verify that ConfigMaps and Secrets referenced in Deployments and StatefulSets actually exist.
# Prevents "CreateContainerConfigError" or missing environment variables.
# Part of the Sentinel philosophy: Proactive configuration auditing.
# Usage: ./k8s_configmap_secret_sync_check.sh [namespace]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [namespace]"
    echo "  namespace: (optional) The namespace to check. Default: all-namespaces"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in kubectl jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

NAMESPACE_ARG="--all-namespaces"
if [ "$#" -ge 1 ] && [ "$1" != "all" ]; then
    NAMESPACE_ARG="-n $1"
fi

echo "Auditing referenced ConfigMaps and Secrets..."

# Fetch resources in bulk to minimize process forks (Bolt)
WORKLOADS=$(kubectl get deployment,statefulset $NAMESPACE_ARG -o json)
CMS=$(kubectl get configmap $NAMESPACE_ARG -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"')
SECRETS=$(kubectl get secret $NAMESPACE_ARG -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"')

# Combine existing resources into a lookup list
EXISTING_RESOURCES=$(printf "%s\n%s" "$CMS" "$SECRETS")

MISSING_FOUND=0

# Extract references and check existence
# References can be in envFrom (configMapRef, secretRef) or env (valueFrom) or volumes (configMap, secret)
REFERENCES=$(echo "$WORKLOADS" | jq -r '
  .items[] | . as $w |
  $w.metadata.namespace as $ns |
  $w.kind as $kind |
  $w.metadata.name as $name |
  $w.spec.template.spec.containers[], ($w.spec.template.spec.initContainers // [])[] |
  (
    (.envFrom[]? | select(.configMapRef) | "ConfigMap\t\($ns)\t\($ns)/\(.configMapRef.name)\t\($kind)/\($name)"),
    (.envFrom[]? | select(.secretRef) | "Secret\t\($ns)\t\($ns)/\(.secretRef.name)\t\($kind)/\($name)"),
    (.env[]? | select(.valueFrom.configMapKeyRef) | "ConfigMap\t\($ns)\t\($ns)/\(.valueFrom.configMapKeyRef.name)\t\($kind)/\($name)"),
    (.env[]? | select(.valueFrom.secretKeyRef) | "Secret\t\($ns)\t\($ns)/\(.valueFrom.secretKeyRef.name)\t\($kind)/\($name)")
  ),
  ($w.spec.template.spec.volumes[]? |
    (select(.configMap) | "ConfigMap\t\($ns)\t\($ns)/\(.configMap.name)\t\($kind)/\($name)"),
    (select(.secret) | "Secret\t\($ns)\t\($ns)/\(.secret.secretName)\t\($kind)/\($name)")
  )
' | sort -u)

if [ -z "$REFERENCES" ]; then
    echo "OK: No ConfigMap or Secret references found."
    exit 0
fi

echo "Checking references..."
printf "%-15s %-20s %-40s %-30s\n" "TYPE" "NAMESPACE" "REFERENCED RESOURCE" "USED BY"
echo "------------------------------------------------------------------------------------------------------------------------"

while IFS=$'\t' read -r type ns ref workload; do
    if ! echo "$EXISTING_RESOURCES" | grep -qx "$ref"; then
        printf "%-15s %-20s %-40s %-30s\n" "$type" "$ns" "${ref#*/}" "$workload"
        MISSING_FOUND=1
    fi
done <<< "$REFERENCES"

if [ "$MISSING_FOUND" -eq 1 ]; then
    echo "------------------------------------------------------------------------------------------------------------------------"
    echo "CRITICAL: Missing referenced resources detected!"
    exit 1
else
    echo "OK: All referenced ConfigMaps and Secrets exist."
    exit 0
fi
