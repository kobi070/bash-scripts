#!/bin/bash

# Script to identify potentially orphaned (unused) ConfigMaps and Secrets in a Kubernetes namespace.
# It compares all existing resources against those referenced in Pods, Deployments, and StatefulSets.
# Note: This is a heuristic and may not account for dynamic loading or external consumers.
# Usage: ./k8s_orphaned_resources.sh [namespace]
# Example: ./k8s_orphaned_resources.sh production

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

echo "Scanning for orphaned ConfigMaps and Secrets in $NAMESPACE_ARG..."

# Get all Secrets and ConfigMaps
# Format: <namespace>/<type>/<name>
ALL_RESOURCES=$(kubectl get configmaps,secrets $NAMESPACE_ARG -o json | jq -r '
  .items[] |
  select(.type != "kubernetes.io/service-account-token") |
  "\(.metadata.namespace)/\(.kind)/\(.metadata.name)"
' | sort)

if [ -z "$ALL_RESOURCES" ]; then
    echo "No ConfigMaps or Secrets found."
    exit 0
fi

# Get all referenced resources from Pods, Deployments, and StatefulSets
# We collect them from Pod specs (which covers Deployments and StatefulSets via their templates)
# and also from the controller objects themselves just in case.
REFERENCED_RESOURCES=$(kubectl get pods,deployments,statefulsets $NAMESPACE_ARG -o json | jq -r '
  .items[] | .metadata.namespace as $ns | .spec.template.spec // .spec |
  (
    (.containers[], .initContainers[]? | select(.env != null) | .env[] | .valueFrom | select(.configMapKeyRef != null) | "\($ns)/ConfigMap/\(.configMapKeyRef.name)"),
    (.containers[], .initContainers[]? | select(.env != null) | .env[] | .valueFrom | select(.secretKeyRef != null) | "\($ns)/Secret/\(.secretKeyRef.name)"),
    (.containers[], .initContainers[]? | select(.envFrom != null) | .envFrom[] | select(.configMapRef != null) | "\($ns)/ConfigMap/\(.configMapRef.name)"),
    (.containers[], .initContainers[]? | select(.envFrom != null) | .envFrom[] | select(.secretRef != null) | "\($ns)/Secret/\(.secretRef.name)"),
    (.volumes[]? | select(.configMap != null) | "\($ns)/ConfigMap/\(.configMap.name)"),
    (.volumes[]? | select(.secret != null) | "\($ns)/Secret/\(.secret.secretName)"),
    (.imagePullSecrets[]? | "\($ns)/Secret/\(.name)")
  )
' | sort -u)

# Use comm to find resources in ALL_RESOURCES but not in REFERENCED_RESOURCES
ORPHANED=$(comm -23 <(echo "$ALL_RESOURCES") <(echo "$REFERENCED_RESOURCES"))

if [ -z "$ORPHANED" ]; then
    echo "OK: All ConfigMaps and Secrets appear to be in use."
else
    echo "WARNING: The following resources might be orphaned (not referenced by Pods, Deployments, or StatefulSets):"
    echo "NAMESPACE/TYPE/NAME"
    echo "$ORPHANED"
fi
