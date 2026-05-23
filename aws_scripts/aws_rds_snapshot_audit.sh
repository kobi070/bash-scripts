#!/bin/bash

# Script to identify RDS snapshots older than a specified number of days.
# Usage: ./aws_rds_snapshot_audit.sh [days_threshold]
# Example: ./aws_rds_snapshot_audit.sh 30

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [days_threshold]"
    echo "  days_threshold: (optional) Age in days. Default: 30"
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

THRESHOLD_DAYS=${1:-30}
THRESHOLD_SECONDS=$((THRESHOLD_DAYS * 86400))
CURRENT_TIME=$(date +%s)

echo "Scanning for RDS snapshots older than $THRESHOLD_DAYS days..."

# Fetch RDS snapshots and filter by age
# Using jq to calculate age and format output
# SnapshotCreateTime is in ISO8601 format
SNAPSHOTS_JSON=$(aws rds describe-db-snapshots --query 'DBSnapshots[*].{ID:DBSnapshotIdentifier,Time:SnapshotCreateTime,DB:DBInstanceIdentifier,Type:SnapshotType}' --output json)

if [[ $(echo "$SNAPSHOTS_JSON" | jq '. | length') -eq 0 ]]; then
    echo "No RDS snapshots found."
    exit 0
fi

STALE_SNAPSHOTS=$(echo "$SNAPSHOTS_JSON" | jq -r --arg current_time "$CURRENT_TIME" --arg threshold "$THRESHOLD_SECONDS" '
  .[] |
  {
    time: .Time,
    id: .ID,
    db: .DB,
    type: .Type,
    ts: (.Time | fromdateiso8601)
  } |
  select((($current_time | tonumber) - .ts) > ($threshold | tonumber)) |
  "\(.time)|\(.id)|\(.db)|\(.type)"
')

if [[ -z "$STALE_SNAPSHOTS" ]]; then
    echo "OK: No snapshots older than $THRESHOLD_DAYS days found."
else
    printf "%-30s | %-40s | %-20s | %-10s\n" "CREATE_TIME" "SNAPSHOT_ID" "DB_INSTANCE" "TYPE"
    printf "%s\n" "------------------------------------------------------------------------------------------------------------------------"
    echo "$STALE_SNAPSHOTS" | while IFS='|' read -r time id db type; do
        printf "%-30s | %-40s | %-20s | %-10s\n" "$time" "$id" "$db" "$type"
    done
fi
