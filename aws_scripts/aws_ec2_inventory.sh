#!/bin/bash

# Script to generate a quick inventory of EC2 instances in a specific region.
# Provides a clean table with Instance ID, State, Public IP, and Name tag.
# Usage: ./aws_ec2_inventory.sh [region]
# Example: ./aws_ec2_inventory.sh us-east-1

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [region]"
    echo "  region: (optional) The AWS region to query. Default: uses configured default"
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

REGION_ARG=""
if [ -n "${1:-}" ]; then
    REGION_ARG="--region $1"
    echo "Querying region: $1..."
fi

echo "Fetching EC2 inventory..."

# Execute AWS CLI command with JMESPath query
# Queries InstanceId, State, PublicIpAddress and the 'Name' tag
# Fallback to '-' if Name tag or PublicIp is missing
aws ec2 describe-instances \
    $REGION_ARG \
    --query "Reservations[].Instances[].{
        ID: InstanceId,
        State: State.Name,
        PublicIP: PublicIpAddress || '-',
        Name: Tags[?Key=='Name'].Value | [0] || '-'
    }" \
    --output table

echo "Done."
