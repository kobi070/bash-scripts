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

# Bolt optimization: Fetch all pods on the node and all PDBs in one go.
# We then use a single jq pipeline to correlate them, reducing process forks from O(N) to O(1).
PODS_JSON=$(kubectl get pods --all-namespaces --field-selector spec.nodeName="$NODE_NAME" -o json)
POD_COUNT=$(echo "$PODS_JSON" | jq '.items | length')

if [ "$POD_COUNT" -eq 0 ]; then
    echo "No pods found on node $NODE_NAME."
    exit 0
fi

PDBS_JSON=$(kubectl get pdb --all-namespaces -o json)

echo "Found $POD_COUNT pods. Checking for potential issues..."
echo "--------------------------------------------------------------------------------"
printf "%-30s %-20s %-10s %-10s %-10s\n" "NAMESPACE/POD" "CONTROLLER" "PDB" "LOCAL-VOL" "READY"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Consolidate pod analysis into a single jq pipeline.
# This replaces multiple calls to jq, wc, and grep inside a shell loop.
# We also implement more accurate PDB matching using label selectors.
echo "$PODS_JSON" | jq -r --argjson pdbs "$PDBS_JSON" '
  .items[] |
  .metadata.namespace as $ns |
  .metadata.name as $name |
  (.metadata.ownerReferences[0].kind // "None") as $owner |
  .status.phase as $phase |
  (.metadata.labels // {}) as $labels |

  # Check for PDB matching label selector
  ([
    $pdbs.items[] |
    select(.metadata.namespace == $ns) |
    (.spec.selector.matchLabels // {}) as $s |
    # A PDB matches if its selector is a subset of the pod labels
    ($s != {} and all($s | to_entries[]; $labels[.key] == .value))
  ] | length) as $pdb_count |
  (if $pdb_count > 0 then "OK (\($pdb_count))" else "MISSING" end) as $pdb_status |

  # Check for local storage (emptyDir)
  (if any(.spec.volumes[]?; .emptyDir != null) then "YES" else "NO" end) as $local_vol |

  "\($ns)/\($name)\t\($owner)\t\($pdb_status)\t\($local_vol)\t\($phase)"
' | while IFS=$'\t' read -r pod owner pdb local_vol phase; do
    printf "%-30s %-20s %-10s %-10s %-10s\n" "$pod" "$owner" "$pdb" "$local_vol" "$phase"
done

echo "--------------------------------------------------------------------------------"
echo "Summary of Concerns:"
echo "- MISSING PDB: These pods might experience downtime as there is no disruption budget defined."
echo "- LOCAL-VOL: Pods with 'emptyDir' volumes will lose their local data upon eviction."
echo "- CONTROLLER 'None': These are standalone pods and will NOT be rescheduled if evicted."
