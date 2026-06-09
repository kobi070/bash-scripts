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

# Bolt optimization: Consolidate API calls and existence checks into a single pipeline.
# This reduces process forks from O(N) to O(1) and uses O(1) lookups for resource verification.
WORKLOADS=$(kubectl get deployment,statefulset $NAMESPACE_ARG -o json)

# Fetch all potential existing resources in one go
EXISTING_RESOURCES_JSON=$(kubectl get configmap,secret $NAMESPACE_ARG -o json | jq -c '
  [.items[] | "\(.metadata.namespace)/\(.metadata.name)"] | reduce .[] as $item ({}; .[$item] = true)
')

echo "Checking references..."

# Extract references and check existence in a single pass using the lookup map
# References can be in envFrom (configMapRef, secretRef) or env (valueFrom) or volumes (configMap, secret)
MISSING_DATA=$(echo "$WORKLOADS" | jq -r --argjson existing "$EXISTING_RESOURCES_JSON" '
  .items[] | . as $w |
  $w.metadata.namespace as $ns |
  $w.kind as $kind |
  $w.metadata.name as $name |
  ($w.spec.template.spec.containers + ($w.spec.template.spec.initContainers // []))[] |
  (
    (.envFrom[]? | select(.configMapRef) | {type: "ConfigMap", ns: $ns, ref: "\($ns)/\(.configMapRef.name)", workload: "\($kind)/\($name)"}),
    (.envFrom[]? | select(.secretRef) | {type: "Secret", ns: $ns, ref: "\($ns)/\(.secretRef.name)", workload: "\($kind)/\($name)"}),
    (.env[]? | select(.valueFrom.configMapKeyRef) | {type: "ConfigMap", ns: $ns, ref: "\($ns)/\(.valueFrom.configMapKeyRef.name)", workload: "\($kind)/\($name)"}),
    (.env[]? | select(.valueFrom.secretKeyRef) | {type: "Secret", ns: $ns, ref: "\($ns)/\(.valueFrom.secretKeyRef.name)", workload: "\($kind)/\($name)"})
  ),
  ($w.spec.template.spec.volumes[]? |
    (select(.configMap) | {type: "ConfigMap", ns: $ns, ref: "\($ns)/\(.configMap.name)", workload: "\($kind)/\($name)"}),
    (select(.secret) | {type: "Secret", ns: $ns, ref: "\($ns)/\(.secret.secretName)", workload: "\($kind)/\($name)"})
  )
  | select(.ref != null and ($existing[.ref] | not))
  | "\(.type)\t\(.ns)\t\(.ref)\t\(.workload)"
' | sort -u)

if [ -z "$MISSING_DATA" ]; then
    echo "OK: All referenced ConfigMaps and Secrets exist."
    exit 0
fi

MISSING_FOUND=1
printf "%-15s %-20s %-40s %-30s\n" "TYPE" "NAMESPACE" "REFERENCED RESOURCE" "USED BY"
echo "------------------------------------------------------------------------------------------------------------------------"

while IFS=$'\t' read -r type ns ref workload; do
    printf "%-15s %-20s %-40s %-30s\n" "$type" "$ns" "${ref#*/}" "$workload"
done <<< "$MISSING_DATA"

if [ "$MISSING_FOUND" -eq 1 ]; then
    echo "------------------------------------------------------------------------------------------------------------------------"
    echo "CRITICAL: Missing referenced resources detected!"
    exit 1
else
    echo "OK: All referenced ConfigMaps and Secrets exist."
    exit 0
fi
