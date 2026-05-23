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

# Bolt optimization: Consolidate all Security Group auditing into a single jq pipeline.
# This reduces process forks from O(N*M) to O(1), where N is SGs and M is rules.
aws ec2 describe-security-groups $REGION_ARG \
    --query 'SecurityGroups[*].{GroupId:GroupId, GroupName:GroupName, IpPermissions:IpPermissions}' \
    --output json | jq -r '
  .[] | .GroupId as $id | .GroupName as $name |
  .IpPermissions[]? |
  select(any(.IpRanges[]?; .CidrIp == "0.0.0.0/0")) |
  .IpProtocol as $proto |
  (.FromPort // "All") as $from |
  (.ToPort // "All") as $to |
  (if $from == $to or $to == "All" then $from | tostring else "\($from)-\($to)" end) as $ports |
  "\($id)\t\($name)\t\($proto)\t\($ports)\t0.0.0.0/0"
' | while IFS=$'\t' read -r id name proto ports cidr; do
    printf "%-25s %-25s %-10s %-15s %-20s\n" "$id" "$name" "$proto" "$ports" "$cidr"
done
