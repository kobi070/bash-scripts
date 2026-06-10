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

# Bolt optimization: Consolidate pod impact analysis into a single jq pipeline.
# This reduces process forks from O(N) to O(1) by performing PDB matching and
# local storage checks within jq for the entire pod set.
# It also improves accuracy by implementing proper label selector matching for PDBs.
echo "$PODS_JSON" | jq -r --argjson pdbs "$PDBS_JSON" '
  .items[] | . as $pod |
  $pod.metadata.namespace as $ns |
  $pod.metadata.name as $name |
  ($pod.metadata.ownerReferences? | .[0].kind // "None") as $owner |
  $pod.status.phase as $phase |
  ($pod.metadata.labels // {}) as $labels |

  # Check for PDB
  # A pod is covered by a PDB if its labels match the PDBs selector
  # We use all(generator; condition) for compatibility with jq < 1.7
  [
    $pdbs.items[] |
    select(.metadata.namespace == $ns) |
    (.spec.selector.matchLabels // {}) as $s |
    select($s != {} and all($s | to_entries | .[]; $labels[.key] == .value))
  ] as $matching_pdbs |
  ($matching_pdbs | length) as $pdb_count |
  (if $pdb_count > 0 then "OK (\($pdb_count))" else "MISSING" end) as $pdb_status |

  # Check for local storage (emptyDir)
  (if ([ $pod.spec.volumes[]?.emptyDir | select(. != null) ] | length > 0) then "YES" else "NO" end) as $local_vol |

  "\($ns)/\($name)\t\($owner)\t\($pdb_status)\t\($local_vol)\t\($phase)"
' | while IFS=$'\t' read -r pod_full_name owner pdb_status local_vol phase; do
    printf "%-30s %-20s %-10s %-10s %-10s\n" "$pod_full_name" "$owner" "$pdb_status" "$local_vol" "$phase"
done

echo "--------------------------------------------------------------------------------"
echo "Summary of Concerns:"
echo "- MISSING PDB: These pods might experience downtime as there is no disruption budget defined."
echo "- LOCAL-VOL: Pods with 'emptyDir' volumes will lose their local data upon eviction."
echo "- CONTROLLER 'None': These are standalone pods and will NOT be rescheduled if evicted."
