#!/bin/bash

# Script to assess the impact of draining a Kubernetes node.
# Identifies pods that might cause issues during a drain.
# Usage: ./k8s_node_drain_helper.sh <node_name>
# Example: ./k8s_node_drain_helper.sh gke-cluster-default-pool-1234

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <node_name>"
    echo "  node_name: The name of the Kubernetes node to analyze."
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

NODE_NAME=$1

# Verify node exists
if ! kubectl get node "$NODE_NAME" &> /dev/null; then
    echo "Error: Node '$NODE_NAME' not found."
    exit 1
fi

echo "Analyzing impact of draining node: $NODE_NAME..."

# Get all pods on the node
PODS_JSON=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$NODE_NAME" -o json)
POD_COUNT=$(echo "$PODS_JSON" | jq '.items | length')

if [ "$POD_COUNT" -eq 0 ]; then
    echo "No pods found on node $NODE_NAME."
    exit 0
fi

echo "Found $POD_COUNT pods. Checking for potential issues..."
echo "--------------------------------------------------------------------------------"
printf "%-30s %-20s %-10s %-10s %-10s\n" "NAMESPACE/POD" "CONTROLLER" "PDB" "LOCAL-VOL" "READY"
echo "--------------------------------------------------------------------------------"

# Get all PDBs once to avoid repeated calls
PDBS_JSON=$(kubectl get pdb --all-namespaces -o json)

echo "$PODS_JSON" | jq -r '.items[] | [.metadata.namespace, .metadata.name, (.metadata.ownerReferences[0].kind // "None"), .status.phase] | @tsv' | while IFS=$'\t' read -r NS NAME OWNER PHASE; do

    # Check for PDB
    # A pod is covered by a PDB if the PDB's selector matches the pod's labels.
    # For simplicity in this script, we'll check if any PDB in the same namespace exists.
    # A more robust check would involve matching selectors.
    PDB_EXISTS=$(echo "$PDBS_JSON" | jq --arg ns "$NS" -r '.items[] | select(.metadata.namespace == $ns) | .metadata.name' | wc -l | xargs)
    PDB_STATUS="MISSING"
    if [ "$PDB_EXISTS" -gt 0 ]; then
        PDB_STATUS="OK ($PDB_EXISTS)"
    fi

    # Check for local storage (emptyDir)
    HAS_LOCAL_STORAGE=$(echo "$PODS_JSON" | jq --arg ns "$NS" --arg name "$NAME" -r '.items[] | select(.metadata.namespace == $ns and .metadata.name == $name) | .spec.volumes[]?.emptyDir' | grep -v "null" | wc -l | xargs)
    LOCAL_VOL="NO"
    if [ "$HAS_LOCAL_STORAGE" -gt 0 ]; then
        LOCAL_VOL="YES"
    fi

    printf "%-30s %-20s %-10s %-10s %-10s\n" "$NS/$NAME" "$OWNER" "$PDB_STATUS" "$LOCAL_VOL" "$PHASE"
done

echo "--------------------------------------------------------------------------------"
echo "Summary of Concerns:"
echo "- MISSING PDB: These pods might experience downtime as there is no disruption budget defined."
echo "- LOCAL-VOL: Pods with 'emptyDir' volumes will lose their local data upon eviction."
echo "- CONTROLLER 'None': These are standalone pods and will NOT be rescheduled if evicted."
