#!/bin/bash

# Script to calculate Kubernetes Pod resource usage percentage relative to limits.
# Requires metrics-server to be installed in the cluster.
# Usage: ./k8s_resource_usage_percentage.sh [namespace]

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
for tool in kubectl jq awk; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

NAMESPACE_ARG="--all-namespaces"
CURRENT_NS="all"
if [ "$#" -ge 1 ] && [ "$1" != "all" ]; then
    NAMESPACE_ARG="-n $1"
    CURRENT_NS="$1"
fi

echo "Fetching resource usage and limits (this may take a few seconds)..."

# Temporary files for joining data
USAGE_FILE=$(mktemp)
LIMITS_FILE=$(mktemp)
trap 'rm -f "$USAGE_FILE" "$LIMITS_FILE"' EXIT

# Get current usage
# kubectl top pod output:
# -A: NAMESPACE POD CPU(m) MEMORY(Mi) (4 cols)
# -n: POD CPU(m) MEMORY(Mi) (3 cols)
# We normalize it to: NAMESPACE POD CPU MEMORY (raw numbers)
kubectl top pod $NAMESPACE_ARG --no-headers | awk -v ns="$CURRENT_NS" '
{
    if (NF == 4) {
        # all-namespaces
        namespace=$1; pod=$2; cpu=$3; mem=$4
    } else {
        # specific namespace
        namespace=ns; pod=$1; cpu=$2; mem=$3
    }
    # Strip units
    sub(/m$/, "", cpu)
    sub(/Mi$/, "", mem)
    print namespace, pod, cpu, mem
}' > "$USAGE_FILE"

# Get limits: namespace, pod, cpu_limit(m), memory_limit(Mi)
# Simplified unit conversion: assumes m/cores and Mi/Gi/M/G
kubectl get pods $NAMESPACE_ARG -o json | jq -r '
  .items[] |
  .metadata.namespace as $ns |
  .metadata.name as $name |
  .spec.containers |
  {
    ns: $ns,
    name: $name,
    cpu: ([.[].resources.limits.cpu // "0"] | map(
      if endswith("m") then .[:-1] | tonumber
      elif . == "0" then 0
      else . | tonumber * 1000
      end
    ) | add),
    mem: ([.[].resources.limits.memory // "0"] | map(
      if endswith("Mi") then .[:-2] | tonumber
      elif endswith("M") then .[:-1] | tonumber
      elif endswith("Gi") then .[:-2] | tonumber * 1024
      elif endswith("G") then .[:-1] | tonumber * 1024
      elif . == "0" then 0
      else . | tonumber / 1024 / 1024 # assuming bytes
      end
    ) | add)
  } |
  "\(.ns) \(.name) \(.cpu) \(.mem)"
' > "$LIMITS_FILE"

echo "--------------------------------------------------------------------------------"
printf "%-20s %-30s %-10s %-10s\n" "NAMESPACE" "POD" "CPU %" "MEM %"
echo "--------------------------------------------------------------------------------"

# Join and calculate
awk '
NR==FNR {
    cpu_lim[$1,$2]=$3
    mem_lim[$1,$2]=$4
    next
}
{
    ns=$1; name=$2; cpu_use=$3; mem_use=$4
    key=ns SUBSEP name

    cpu_p="N/A"; mem_p="N/A"

    if (key in cpu_lim && cpu_lim[key] > 0) {
        cpu_p=sprintf("%.1f%%", (cpu_use / cpu_lim[key]) * 100)
    }
    if (key in mem_lim && mem_lim[key] > 0) {
        mem_p=sprintf("%.1f%%", (mem_use / mem_lim[key]) * 100)
    }

    printf "%-20s %-30s %-10s %-10s\n", ns, name, cpu_p, mem_p
}' "$LIMITS_FILE" "$USAGE_FILE" | sort

echo "--------------------------------------------------------------------------------"
echo "Note: N/A indicates no limit is defined for that resource."
