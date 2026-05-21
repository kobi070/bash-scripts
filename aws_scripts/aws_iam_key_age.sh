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
for tool in aws jq base64 awk; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

MAX_AGE_DAYS=${1:-90}
# Security Pattern: validate numeric input
if [[ ! "$MAX_AGE_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: max_age_days must be a positive integer."
    exit 1
fi

echo "Generating IAM credential report for initial scan..."

# Bolt optimization: We use O(1) credential report instead of O(N) per-user calls for initial scan.
aws iam generate-credential-report --query 'State' --output text > /dev/null

# Poll for report completion
MAX_ATTEMPTS=10
ATTEMPT=1
STATE="STARTED"
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    STATE=$(aws iam generate-credential-report --query 'State' --output text)
    if [ "$STATE" == "COMPLETE" ]; then
        break
    fi
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ "$STATE" != "COMPLETE" ]; then
    echo "Error: Failed to generate credential report after $MAX_ATTEMPTS attempts."
    exit 1
fi

echo "Scanning IAM access keys older than $MAX_AGE_DAYS days..."

# Get current time in seconds since epoch
NOW=$(date +%s)

# Calculate threshold date for initial awk filtering (ISO 8601)
# Use portable date command for GNU/BSD
if date -u -d "90 days ago" +"%Y-%m-%dT%H:%M:%SZ" &> /dev/null; then
    THRESHOLD_DATE=$(date -u -d "$MAX_AGE_DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ")
else
    THRESHOLD_DATE=$(date -u -v-"${MAX_AGE_DAYS}d" +"%Y-%m-%dT%H:%M:%SZ")
fi

# Fetch report and filter for candidate users with potentially stale keys
# Indices (1-based): user(1), key1_active(9), key1_rotated(10), key2_active(14), key2_rotated(15)
USERS=$(aws iam get-credential-report --query 'Content' --output text | base64 --decode | awk -F',' -v limit="$THRESHOLD_DATE" '
  NR > 1 {
    user = $1
    key1_active = $9
    key1_rotated = $10
    key2_active = $14
    key2_rotated = $15
    if ((key1_active == "true" && key1_rotated < limit) || (key2_active == "true" && key2_rotated < limit)) {
      print user
    }
  }
')

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
