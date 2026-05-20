#!/bin/bash

# Script to audit Docker image history for security risks and optimization.
# Detects sensitive keywords in commands and identifies oversized layers.
# Part of the Sentinel and Bolt philosophies.
# Usage: ./docker_image_history_audit.sh [image_name:tag]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [image_name:tag]"
    echo "  image_name:tag: The Docker image to audit."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if [ "$#" -ne 1 ]; then
    usage
fi

IMAGE=$1

# Check for required tools
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH."
    exit 1
fi

echo "Auditing history for image: $IMAGE"

# Capture history once (Bolt)
HISTORY=$(docker history --no-trunc --format "{{.CreatedBy}}\t{{.Size}}" "$IMAGE")

echo "--- Security Audit (Sensitive Keywords) ---"
# Keywords that might indicate secret leakage in Docker layers
SENSITIVE_KEYWORDS="PASS|SECRET|KEY|TOKEN|AUTH|CRED"
SENSITIVE_MATCHES=$(echo "$HISTORY" | grep -Ei "$SENSITIVE_KEYWORDS" || true)

if [ -n "$SENSITIVE_MATCHES" ]; then
    echo "WARNING: Potential sensitive data found in image layers:"
    echo "$SENSITIVE_MATCHES" | cut -f1 | sed 's/^/  [!] /'
else
    echo "OK: No common sensitive keywords found in layer commands."
fi

echo -e "\n--- Layer Size Audit (Top 5 largest layers) ---"
# Identification of large layers for optimization
echo "$HISTORY" | sort -t $'\t' -k2 -h -r | head -n 5 | while IFS=$'\t' read -r cmd size; do
    printf "%-10s %s\n" "$size" "$(echo "$cmd" | cut -c1-100)..."
done

echo -e "\nAudit complete."
