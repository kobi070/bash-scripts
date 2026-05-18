#!/bin/bash

# Script to identify Deployments and StatefulSets without associated PodDisruptionBudgets (PDB).
# Useful for ensuring high availability during node maintenance.
# Part of the Sentinel philosophy: Identifying availability risks.
# Usage: ./k8s_audit_pdb.sh [namespace]
# Example: ./k8s_audit_pdb.sh production

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
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

NAMESPACE_ARG="--all-namespaces"
if [ "$#" -ge 1 ] && [ "$1" != "all" ]; then
    NAMESPACE_ARG="-n $1"
fi

echo "Auditing PodDisruptionBudgets for Deployments and StatefulSets..."

# Fetch all PDBs and workloads in one go (or two) to reduce process forks
PDBS_JSON=$(kubectl get pdb $NAMESPACE_ARG -o json)
WORKLOADS_JSON=$(kubectl get deployment,statefulset $NAMESPACE_ARG -o json)

# Correlate workloads with PDBs using jq
# A workload is protected if there is a PDB in the same namespace whose selector matches the workload's labels
RESULT=$(echo "$WORKLOADS_JSON" | jq -r --argjson pdbs "$PDBS_JSON" '
  .items[] | . as $workload |
  $workload.metadata.namespace as $ns |
  $workload.metadata.name as $name |
  $workload.kind as $kind |
  ($workload.spec.template.metadata.labels // {}) as $labels |

  # Find if any PDB in the same namespace matches
  [
    $pdbs.items[] |
    select(.metadata.namespace == $ns) |
    (.spec.selector.matchLabels // {}) as $s |
    # A PDB matches if its selector is a subset of the workload labels
    # We also check that the selector is not empty to avoid false positives (empty selector matches everything)
    ($s != {} and ($s | to_entries | all($labels[.key] == .value)))
  ] | any | not | select(.) |
  "\($ns)\t\($kind)\t\($name)"
')

if [ -z "$RESULT" ]; then
    echo "OK: All Deployments and StatefulSets have at least one matching PodDisruptionBudget."
    exit 0
else
    echo "WARNING: The following workloads are missing a PodDisruptionBudget:"
    printf "%-20s %-15s %-30s\n" "NAMESPACE" "KIND" "NAME"
    echo "$RESULT" | while IFS=$'\t' read -r ns kind name; do
        printf "%-20s %-15s %-30s\n" "$ns" "$kind" "$name"
    done
    exit 1
fi
