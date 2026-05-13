#!/bin/bash

# Script to list AWS EBS volumes that are in 'available' state (not attached to any instance).
# Useful for cost optimization by identifying unattached storage.
# Usage: ./aws_find_unused_ebs.sh [region]
# Example: ./aws_find_unused_ebs.sh us-east-1

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [region]"
    echo "  region: (optional) AWS region to check. Default: AWS CLI default region"
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

REGION_ARG=""
if [ "$#" -ge 1 ]; then
    REGION_ARG="--region $1"
fi

echo "Searching for unused EBS volumes (state: available)..."

# Describe volumes filtering by state 'available'
UNUSED_VOLUMES=$(aws ec2 describe-volumes $REGION_ARG --filters "Name=status,Values=available" --query "Volumes[*].{ID:VolumeId,Size:Size,Zone:AvailabilityZone,Type:VolumeType,Created:CreateTime}" --output json)

NUM_UNUSED=$(echo "$UNUSED_VOLUMES" | jq '. | length')

if [ "$NUM_UNUSED" -eq 0 ]; then
    echo "No unused EBS volumes found."
    exit 0
else
    echo "Found $NUM_UNUSED unused EBS volume(s):"
    echo "$UNUSED_VOLUMES" | jq -r '(["VOLUME_ID", "SIZE(GB)", "ZONE", "TYPE", "CREATED"] | (., map(length * "-"))), (.[] | [.ID, .Size, .Zone, .Type, .Created]) | @tsv' | column -t -s $'\t'
fi
