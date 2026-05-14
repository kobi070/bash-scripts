#!/bin/bash

# Script to audit AWS Security Groups for overly permissive rules (0.0.0.0/0).
# Useful for security posture management and identifying potential exposures.
# Usage: ./aws_sg_audit.sh [region]
# Example: ./aws_sg_audit.sh us-east-1

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [region]"
    echo "  region: (optional) The AWS region to audit. Default: current AWS CLI config"
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

echo "Auditing Security Groups for open rules (0.0.0.0/0)..."
echo "----------------------------------------------------------------------------------------------------"
printf "%-25s %-25s %-10s %-15s %-20s\n" "SG ID" "SG NAME" "PROTOCOL" "PORT RANGE" "IP RANGE"
echo "----------------------------------------------------------------------------------------------------"

# Describe security groups and filter for those with 0.0.0.0/0
aws ec2 describe-security-groups $REGION_ARG \
    --query 'SecurityGroups[*].{GroupId:GroupId, GroupName:GroupName, IpPermissions:IpPermissions}' \
    --output json | jq -c '.[]' | while read -r sg; do

    SG_ID=$(echo "$sg" | jq -r '.GroupId')
    SG_NAME=$(echo "$sg" | jq -r '.GroupName')

    echo "$sg" | jq -c '.IpPermissions[]?' | while read -r rule; do
        # Check for 0.0.0.0/0 in IpRanges
        OPEN_RULE=$(echo "$rule" | jq -r '.IpRanges[]? | select(.CidrIp == "0.0.0.0/0") | .CidrIp')

        if [ -n "$OPEN_RULE" ]; then
            PROTOCOL=$(echo "$rule" | jq -r '.IpProtocol')
            FROM_PORT=$(echo "$rule" | jq -r '.FromPort // "All"')
            TO_PORT=$(echo "$rule" | jq -r '.ToPort // "All"')

            PORT_RANGE="$FROM_PORT"
            if [ "$FROM_PORT" != "$TO_PORT" ] && [ "$TO_PORT" != "All" ]; then
                PORT_RANGE="$FROM_PORT-$TO_PORT"
            fi

            printf "%-25s %-25s %-10s %-15s %-20s\n" "$SG_ID" "$SG_NAME" "$PROTOCOL" "$PORT_RANGE" "0.0.0.0/0"
        fi
    done
done
