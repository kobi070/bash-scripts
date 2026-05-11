#!/bin/bash
# aws_list_old_ebs_snapshots.sh - Lists AWS EBS snapshots older than a specified number of days.

set -euo pipefail

usage() {
    echo "Usage: $0 [-d <days>] [-r <region>]"
    echo "  -d <days>    List snapshots older than this many days (defaults to 30)"
    echo "  -r <region>  AWS region (defaults to current configured region)"
    echo "  -h, --help   Display this help message"
    exit 1
}

DAYS=30
REGION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            DAYS="$2"
            shift 2
            ;;
        -r|--region)
            REGION="--region $2"
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
if ! command -v aws &> /dev/null; then
    echo "Error: aws CLI is not installed."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed."
    exit 1
fi

# Calculate the cutoff date
if [[ "$OSTYPE" == "darwin"* ]]; then
    CUTOFF_DATE=$(date -v-"${DAYS}"d +%Y-%m-%d)
else
    CUTOFF_DATE=$(date -d "${DAYS} days ago" +%Y-%m-%d)
fi

echo "Searching for EBS snapshots created before: $CUTOFF_DATE"

# Query AWS for snapshots owned by the account
# We filter by 'StartTime' and check if it is less than the cutoff date
# Note: StartTime is in ISO8601 format (e.g., 2023-05-10T15:00:00.000Z)
# jq's string comparison works well here for dates in this format.

QUERY="Snapshots[?StartTime<='${CUTOFF_DATE}'].{ID:SnapshotId,Time:StartTime,Size:VolumeSize,Desc:Description}"

# shellcheck disable=SC2086
RESULTS=$(aws ec2 describe-snapshots --owner-ids self $REGION --query "$QUERY" --output json)

COUNT=$(echo "$RESULTS" | jq '. | length')

if [[ $COUNT -eq 0 ]]; then
    echo "No snapshots found older than $DAYS days."
else
    echo "Found $COUNT snapshots older than $DAYS days:"
    echo "--------------------------------------------------------------------------------"
    printf "%-25s | %-25s | %-5s | %s\n" "Snapshot ID" "Start Time" "Size" "Description"
    echo "--------------------------------------------------------------------------------"
    echo "$RESULTS" | jq -r '.[] | "\(.ID) | \(.Time) | \(.Size)GB | \(.Desc)"' | while read -r line; do
        printf "%s\n" "$line"
    done
    echo "--------------------------------------------------------------------------------"
fi
