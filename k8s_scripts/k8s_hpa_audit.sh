#!/bin/bash

# Script to audit Kubernetes HorizontalPodAutoscalers (HPA).
# Highlights HPAs that are at their maximum replica limit or have high utilization.
# Usage: ./k8s_hpa_audit.sh [namespace]
# Example: ./k8s_hpa_audit.sh production

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

echo "Auditing HPAs in $NAMESPACE_ARG..."

HPA_DATA=$(kubectl get hpa $NAMESPACE_ARG -o json)

if [[ $(echo "$HPA_DATA" | jq '.items | length') -eq 0 ]]; then
    echo "No HPAs found."
    exit 0
fi

# Extract and analyze HPA status
# We look for HPAs where currentReplicas == maxReplicas
ANALYSIS=$(echo "$HPA_DATA" | jq -r '
  .items[] |
  .metadata.namespace as $ns |
  .metadata.name as $name |
  .status.currentReplicas as $curr |
  .spec.maxReplicas as $max |
  .spec.minReplicas as $min |
  .status.currentMetrics[0].resource.current.averageUtilization // "N/A" as $util |
  .spec.metrics[0].resource.target.averageUtilization // "N/A" as $target |
  "\($ns)|\($name)|\($curr)|\($max)|\($min)|\($util)|\($target)"
')

printf "%-20s | %-30s | %-6s | %-6s | %-6s | %-10s | %-10s\n" "NAMESPACE" "HPA_NAME" "CURR" "MAX" "MIN" "UTIL%" "TARGET%"
printf "%s\n" "----------------------------------------------------------------------------------------------------------------------------"

echo "$ANALYSIS" | while IFS='|' read -r ns name curr max min util target; do
    STATUS=""
    if [[ "$curr" -eq "$max" ]]; then
        STATUS=" [MAXED]"
    fi
    printf "%-20s | %-30s | %-6s | %-6s | %-6s | %-10s | %-10s%s\n" "$ns" "$name" "$curr" "$max" "$min" "$util" "$target" "$STATUS"
done
