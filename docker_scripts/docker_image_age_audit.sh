#!/bin/bash

# Script to list local Docker images with their age.
# Useful for identifying old images for cleanup or vulnerability assessment.
# Usage: ./docker_image_age_audit.sh [threshold_days]
# Example: ./docker_image_age_audit.sh 30

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [threshold_days]"
    echo "  threshold_days: (optional) Only list images older than this many days. Default: 0 (all)"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

THRESHOLD_DAYS="${1:-0}"
CURRENT_TS=$(date +%s)

echo "Auditing local Docker images by age..."
echo "----------------------------------------------------------------------------------------------------"
printf "%-40s %-20s %-20s %-10s\n" "REPOSITORY:TAG" "IMAGE ID" "CREATED AT" "AGE (DAYS)"
echo "----------------------------------------------------------------------------------------------------"

# Get images and their creation timestamps
# Format: repository:tag|id|timestamp (RFC3339)
docker images --format "{{.Repository}}:{{.Tag}}|{{.ID}}|{{.CreatedAt}}" | while read -r line; do
    REPO_TAG=$(echo "$line" | cut -d'|' -f1)
    IMAGE_ID=$(echo "$line" | cut -d'|' -f2)
    CREATED_STR=$(echo "$line" | cut -d'|' -f3)

    # docker images --format "{{.CreatedAt}}" returns something like "2023-11-01 10:00:00 +0000 UTC"
    # or sometimes just "2 days ago" depending on docker version/settings, but we want ISO-like for parsing.
    # To be robust across environments and Bolt-compliant, we use docker inspect for the exact timestamp.

    # Actually, {{.CreatedAt}} is usually formatted. Let's use docker inspect for raw timestamp.
    RAW_TS=$(docker inspect "$IMAGE_ID" --format '{{.Created}}')

    # Parse RFC3339 to Unix timestamp
    # Use jq for portable date parsing (Bolt pattern)
    # Ensure RAW_TS is quoted for jq
    CREATED_TS=$(echo "\"$RAW_TS\"" | jq -r 'fromdate')

    AGE_SECONDS=$((CURRENT_TS - CREATED_TS))
    AGE_DAYS=$((AGE_SECONDS / 86400))

    if [ "$AGE_DAYS" -ge "$THRESHOLD_DAYS" ]; then
        # Format the date for display (portable date format)
        CREATED_DATE=$(date -u -d "@$CREATED_TS" +"%Y-%m-%d" 2>/dev/null || date -u -r "$CREATED_TS" +"%Y-%m-%d")
        printf "%-40s %-20s %-20s %-10s\n" "$REPO_TAG" "$IMAGE_ID" "$CREATED_DATE" "$AGE_DAYS"
    fi
done | sort -k4 -n -r
