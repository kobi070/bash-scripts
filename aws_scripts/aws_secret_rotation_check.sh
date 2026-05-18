#!/bin/bash

# Script to identify unrotated or stale secrets in AWS Secrets Manager.
# It checks if rotation is enabled and when the secret was last rotated/changed.
# Usage: ./aws_secret_rotation_check.sh [max_days]
# Example: ./aws_secret_rotation_check.sh 90

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [max_days]"
    echo "  max_days: (optional) Warn if secret has not been changed in this many days. Default: 90"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in aws jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

MAX_DAYS=${1:-90}
MAX_SECONDS=$((MAX_DAYS * 86400))
CURRENT_EPOCH=$(date +%s)

echo "Checking AWS Secrets Manager for secrets older than $MAX_DAYS days..."

# Fetch all secrets
# Bolt optimization: Use direct extraction of multiple fields into TSV format for robust parsing
SECRETS_JSON=$(aws secretsmanager list-secrets --output json)

if [ "$(echo "$SECRETS_JSON" | jq '.SecretList | length')" -eq 0 ]; then
    echo "No secrets found in AWS Secrets Manager."
    exit 0
fi

echo "--------------------------------------------------------------------------------"
printf "%-30s | %-10s | %-15s | %s\n" "SECRET NAME" "ROTATION" "LAST CHANGED" "STATUS"
echo "--------------------------------------------------------------------------------"

# Process secrets
echo "$SECRETS_JSON" | jq -r '.SecretList[] | "\(.Name)\t\(.RotationEnabled // false)\t\(.LastChangedDate // .CreatedDate)"' | while IFS=$'\t' read -r name rot_enabled last_changed; do

    # Handle different date formats or missing dates
    if [ "$last_changed" == "null" ]; then
        LAST_EPOCH=$CURRENT_EPOCH
        DATE_STR="Unknown"
    else
        LAST_EPOCH=$(date -d "$last_changed" +%s)
        DATE_STR=$(date -d "@$LAST_EPOCH" +"%Y-%m-%d")
    fi

    AGE_SECONDS=$((CURRENT_EPOCH - LAST_EPOCH))
    AGE_DAYS=$((AGE_SECONDS / 86400))

    STATUS="OK"
    if [ "$rot_enabled" == "false" ]; then
        STATUS="NO_ROTATION"
    fi

    if [ "$AGE_SECONDS" -gt "$MAX_SECONDS" ]; then
        STATUS="${STATUS},STALE"
    fi

    printf "%-30s | %-10s | %-15s | %s\n" "${name:0:30}" "$rot_enabled" "$DATE_STR" "$STATUS"
done

echo "--------------------------------------------------------------------------------"
echo "Audit complete."
