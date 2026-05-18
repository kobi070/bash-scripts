#!/bin/bash

# Script to identify IAM access keys older than 90 days.
# Part of the Sentinel philosophy: Identifying unrotated credentials.
# Uses jq for portable date calculations.
# Usage: ./aws_iam_key_age.sh [max_age_days]
# Example: ./aws_iam_key_age.sh 90

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [max_age_days]"
    echo "  max_age_days: (optional) Maximum age in days. Default: 90"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v aws &> /dev/null; then
    echo "Error: aws CLI is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

MAX_AGE_DAYS=${1:-90}
# Security Pattern: validate numeric input
if [[ ! "$MAX_AGE_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: max_age_days must be a positive integer."
    exit 1
fi

echo "Scanning IAM access keys older than $MAX_AGE_DAYS days..."

# Get current time in seconds since epoch
NOW=$(date +%s)

# Fetch all users
USERS=$(aws iam list-users --query 'Users[*].UserName' --output text)

STALE_KEYS_FOUND=0

printf "%-25s %-25s %-20s %-5s\n" "USER" "KEY_ID" "CREATED_AT" "AGE_DAYS"

for USER in $USERS; do
    # Fetch keys for each user
    # Bolt optimization: Use --query to extract only necessary fields
    KEYS_JSON=$(aws iam list-access-keys --user-name "$USER" --output json)

    # Process with jq
    # Convert CreateDate to epoch and calculate age
    STALE_KEYS=$(echo "$KEYS_JSON" | jq -r --arg now "$NOW" --arg max_age "$MAX_AGE_DAYS" '
      .AccessKeyMetadata[] |
      .AccessKeyId as $id |
      .CreateDate as $created |
      ($created | fromdate) as $epoch |
      (($now | tonumber) - $epoch) / 86400 | floor as $age |
      select($age > ($max_age | tonumber)) |
      "\($age)\t\($id)\t\($created)"
    ')

    if [ -n "$STALE_KEYS" ]; then
        STALE_KEYS_FOUND=1
        echo "$STALE_KEYS" | while IFS=$'\t' read -r age key_id created; do
            printf "%-25s %-25s %-20s %-5s\n" "$USER" "$key_id" "$created" "$age"
        done
    fi
done

if [ "$STALE_KEYS_FOUND" -eq 0 ]; then
    echo "OK: No IAM access keys older than $MAX_AGE_DAYS days found."
    exit 0
else
    exit 1
fi
