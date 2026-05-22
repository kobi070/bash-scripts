#!/bin/bash

# aws_resource_tag_audit.sh - Audits EC2 instances and S3 buckets for missing mandatory tags.
# Identifies resources that lack required metadata for cost allocation and ownership.
# Part of the DevOps Automation Hub.

set -euo pipefail

# Configurable mandatory tags
MANDATORY_TAGS=("Owner" "Environment")

usage() {
    echo "Usage: $0 [region]"
    echo "  region: (optional) The AWS region to audit. Default: current AWS CLI config"
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Verify dependencies
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

echo "Mandatory Tags: ${MANDATORY_TAGS[*]}"
echo "================================================================================"

echo "Auditing EC2 Instances..."
echo "--------------------------------------------------------------------------------"

# Fetch EC2 data
EC2_DATA=$(aws ec2 describe-instances $REGION_ARG --query 'Reservations[*].Instances[*].{InstanceId:InstanceId, Tags:Tags}' --output json)

echo "$EC2_DATA" | jq -c '.[][]' | while read -r instance; do
    ID=$(echo "$instance" | jq -r '.InstanceId')
    MISSING=()
    for tag in "${MANDATORY_TAGS[@]}"; do
        # Use jq to check if the tag exists
        EXISTS=$(echo "$instance" | jq -r --arg TAG "$tag" '.Tags // [] | any(.Key == $TAG)')
        if [ "$EXISTS" == "false" ]; then
            MISSING+=("$tag")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "EC2 [$ID] is missing tags: ${MISSING[*]}"
    fi
done

echo -e "\nAuditing S3 Buckets..."
echo "--------------------------------------------------------------------------------"

# List all buckets
BUCKETS=$(aws s3api list-buckets --query 'Buckets[*].Name' --output json)

echo "$BUCKETS" | jq -r '.[]' | while read -r bucket; do
    # get-bucket-tagging returns an error if no tags exist
    TAG_OUTPUT=$(aws s3api get-bucket-tagging --bucket "$bucket" $REGION_ARG 2>/dev/null || true)

    MISSING=()
    if [ -z "$TAG_OUTPUT" ]; then
        # No tags at all
        MISSING=("${MANDATORY_TAGS[@]}")
    else
        for tag in "${MANDATORY_TAGS[@]}"; do
            EXISTS=$(echo "$TAG_OUTPUT" | jq -r --arg TAG "$tag" '.TagSet // [] | any(.Key == $TAG)')
            if [ "$EXISTS" == "false" ]; then
                MISSING+=("$tag")
            fi
        done
    fi

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "S3 [$bucket] is missing tags: ${MISSING[*]}"
    fi
done

echo "================================================================================"
echo "Audit complete."
