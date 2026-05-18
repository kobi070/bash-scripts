#!/bin/bash
# k8s_unused_secrets_finder.sh - Identifies Kubernetes secrets in a namespace that are not currently used by any Pod or ServiceAccount.

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
for cmd in kubectl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed and is required."
        exit 1
    fi
done

echo "Scanning for unused secrets in namespace: $NAMESPACE"

# Get all secrets in the namespace
ALL_SECRETS=$(kubectl get secrets -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)

if [[ -z "$ALL_SECRETS" ]]; then
    echo "No secrets found in namespace: $NAMESPACE (or namespace does not exist)."
    exit 0
fi

# Get all referenced secrets from Pods (Containers, InitContainers, Volumes, imagePullSecrets)
USED_SECRETS_PODS=$(kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
  .items[]? |
  (
    (.spec.containers[]?.env[]? | select(.valueFrom.secretKeyRef != null) | .valueFrom.secretKeyRef.name),
    (.spec.containers[]?.envFrom[]? | select(.secretRef != null) | .secretRef.name),
    (.spec.volumes[]? | select(.secret != null) | .secret.secretName),
    (.spec.imagePullSecrets[]?.name),
    (.spec.initContainers[]?.env[]? | select(.valueFrom.secretKeyRef != null) | .valueFrom.secretKeyRef.name),
    (.spec.initContainers[]?.envFrom[]? | select(.secretRef != null) | .secretRef.name)
  )
' | sort | uniq || true)

# Get referenced secrets from ServiceAccounts
USED_SECRETS_SA=$(kubectl get serviceaccounts -n "$NAMESPACE" -o json 2>/dev/null | jq -r '.items[]?.imagePullSecrets[]?.name' | sort | uniq || true)

# Combine used secrets
USED_SECRETS=$(echo -e "${USED_SECRETS_PODS}\n${USED_SECRETS_SA}" | grep -v '^$' | sort | uniq || true)

UNUSED_COUNT=0
echo "------------------------------------------------"
echo "Potential Unused Secrets:"

while read -r SECRET; do
    [[ -z "$SECRET" ]] && continue

    # Skip default service account tokens which are often named 'default-token-xxxxx' or similar
    # In newer K8s versions, these are often not explicitly created as secrets anymore, but some still exist.
    if [[ "$SECRET" =~ default-token- ]]; then
        continue
    fi

    # Check if the secret is in the USED_SECRETS list
    if ! echo "$USED_SECRETS" | grep -qxw "$SECRET"; then
        echo "- $SECRET"
        ((UNUSED_COUNT++))
    fi
done <<< "$ALL_SECRETS"

echo "------------------------------------------------"
if [[ $UNUSED_COUNT -eq 0 ]]; then
    echo "No unused secrets found."
else
    echo "Total potential unused secrets: $UNUSED_COUNT"
    echo "Note: Some secrets might be used by Helm, Ingress, or other resources not scanned by this script."
fi
