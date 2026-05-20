#!/bin/bash

# Script to identify all EBS volumes in the current region that are not encrypted.
# Part of the Sentinel philosophy: Infrastructure security compliance.
# Usage: ./aws_ebs_unencrypted_volumes.sh [region]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [region]"
    echo "  region: (optional) AWS region to check. Default: uses configured region."
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

REGION_ARG=""
if [ "$#" -ge 1 ]; then
    REGION_ARG="--region $1"
fi

echo "Auditing unencrypted EBS volumes..."

# Use AWS CLI query for performance (Bolt)
# We extract VolumeId, Size, State, and the Name tag if it exists
UNENCRYPTED_VOLUMES=$(aws ec2 describe-volumes $REGION_ARG \
    --filters "Name=encrypted,Values=false" \
    --query 'Volumes[*].[VolumeId, Size, State, Tags[?Key==`Name`].Value | [0]]' \
    --output json)

COUNT=$(echo "$UNENCRYPTED_VOLUMES" | jq '. | length')

if [ "$COUNT" -eq 0 ]; then
    echo "OK: No unencrypted EBS volumes found."
    exit 0
else
    echo "WARNING: Found $COUNT unencrypted EBS volumes:"
    printf "%-25s %-10s %-15s %-30s\n" "VOLUME ID" "SIZE(GB)" "STATE" "NAME"
    echo "----------------------------------------------------------------------------------------------------"
    echo "$UNENCRYPTED_VOLUMES" | jq -r '.[] | @tsv' | while IFS=$'\t' read -r id size state name; do
        printf "%-25s %-10s %-15s %-30s\n" "$id" "$size" "$state" "${name:-N/A}"
    done
    exit 1
fi
