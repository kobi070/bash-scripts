#!/bin/bash

# Script to identify EC2 instances with public IP addresses.
# Useful for identifying potential security exposures in AWS.
# Follows Sentinel principles for infrastructure security auditing.
# Usage: ./aws_ec2_public_ip_checker.sh [region]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [region]"
    echo "  region: (optional) The AWS region to check. Default: current AWS CLI config"
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

echo "Checking for EC2 instances with public IP addresses..."
echo "--------------------------------------------------------------------------------"
printf "%-20s %-20s %-15s %-15s\n" "INSTANCE_ID" "NAME" "PUBLIC_IP" "STATE"
echo "--------------------------------------------------------------------------------"

# Query EC2 instances and filter for those with a PublicIpAddress
# Using a pipe delimiter to handle Names with spaces
aws ec2 describe-instances $REGION_ARG \
    --query 'Reservations[*].Instances[*].{InstanceId:InstanceId, Name:Tags[?Key==`Name`].Value | [0], PublicIp:PublicIpAddress, State:State.Name}' \
    --output json | jq -r '
      flatten |
      .[] |
      select(.PublicIp != null) |
      "\(.InstanceId)|\(.Name // "N/A")|\(.PublicIp)|\(.State)"
    ' | while IFS='|' read -r id name ip state; do
        printf "%-20s %-20s %-15s %-15s\n" "$id" "$name" "$ip" "$state"
    done

echo "--------------------------------------------------------------------------------"
echo "Check complete."
