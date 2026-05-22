#!/bin/bash
# k8s_unused_secrets_finder.sh - Identifies Kubernetes secrets in a namespace that are not currently used by any Pod or ServiceAccount.
# Optimized with Bolt principles: Consolidates API calls and uses efficient set operations.

set -euo pipefail

usage() {
    echo "Usage: $0 [-n <namespace>]"
    echo "  -n <namespace>  Namespace to scan (defaults to 'default')"
    echo "  -h, --help      Display this help message"
    exit 1
}

NAMESPACE="default"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Verify dependencies
for cmd in kubectl jq comm; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed and is required."
        exit 1
    fi
done

echo "Scanning for unused secrets in namespace: $NAMESPACE"

# Get all secrets in the namespace, excluding default service account tokens
# Bolt optimization: Filter and sort early for efficient set subtraction
ALL_SECRETS=$(kubectl get secrets -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" 2>/dev/null | grep -v "default-token-" | sort || true)

if [[ -z "$ALL_SECRETS" ]]; then
    echo "No secrets found in namespace: $NAMESPACE (or namespace does not exist)."
    exit 0
fi

# Get all referenced secrets from Pods and ServiceAccounts
# Bolt optimization: Consolidate two kubectl calls into one and use a single jq pipeline (O(1) API calls)
USED_SECRETS=$(kubectl get pods,serviceaccounts -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
  .items[]? |
  if .kind == "Pod" then
    .spec | (
      .containers[]?.env[]?.valueFrom.secretKeyRef.name,
      .containers[]?.envFrom[]?.secretRef.name,
      .initContainers[]?.env[]?.valueFrom.secretKeyRef.name,
      .initContainers[]?.envFrom[]?.secretRef.name,
      .volumes[]?.secret.secretName,
      .imagePullSecrets[]?.name
    )
  elif .kind == "ServiceAccount" then
    .imagePullSecrets[]?.name
  else
    empty
  end | select(. != null)
' | sort -u)

# Bolt optimization: Replace O(N) while-read loop with O(N+M) set subtraction using comm
UNUSED_SECRETS=$(comm -23 <(echo "$ALL_SECRETS") <(echo "$USED_SECRETS"))

echo "------------------------------------------------"
echo "Potential Unused Secrets:"

if [[ -z "$UNUSED_SECRETS" ]]; then
    echo "No unused secrets found."
    UNUSED_COUNT=0
else
    echo "$UNUSED_SECRETS" | sed 's/^/- /'
    UNUSED_COUNT=$(echo "$UNUSED_SECRETS" | grep -vc '^$')
fi

echo "------------------------------------------------"
if [[ $UNUSED_COUNT -gt 0 ]]; then
    echo "Total potential unused secrets: $UNUSED_COUNT"
    echo "Note: Some secrets might be used by Helm, Ingress, or other resources not scanned by this script."
fi
