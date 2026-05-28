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

# Bolt optimization: Consolidate EC2 tag auditing into a single jq pipeline.
# This reduces process forks from O(N*M) to O(1), where N is instances and M is mandatory tags.
# We pre-calculate the JSON array of targets to avoid redundant forks.
TARGETS_JSON=$(printf '%s\n' "${MANDATORY_TAGS[@]}" | jq -R . | jq -s -c .)
aws ec2 describe-instances $REGION_ARG --query 'Reservations[*].Instances[*].{InstanceId:InstanceId, Tags:Tags}' --output json | \
    jq -r --argjson targets "$TARGETS_JSON" '
      .[][] | .InstanceId as $id | (.Tags // []) as $tags |
      ($targets - [ $tags[].Key ]) as $missing |
      select(($missing | length) > 0) |
      "\($id)\t\($missing | join(" "))"
    ' | while IFS=$'\t' read -r id missing; do
        echo "EC2 [$id] is missing tags: $missing"
    done

echo -e "\nAuditing S3 Buckets..."
echo "--------------------------------------------------------------------------------"

# Bolt optimization: Consolidate S3 tag auditing into a single jq call per bucket.
# This reduces process forks from O(M) to O(1) per bucket.
# Re-use TARGETS_JSON to eliminate forks inside the loop.
aws s3api list-buckets --query 'Buckets[*].Name' --output json | jq -r '.[]' | while read -r bucket; do
    # get-bucket-tagging returns an error if no tags exist
    TAG_OUTPUT=$(aws s3api get-bucket-tagging --bucket "$bucket" $REGION_ARG 2>/dev/null || echo '{"TagSet": []}')

    MISSING=$(echo "$TAG_OUTPUT" | jq -r --argjson targets "$TARGETS_JSON" '
      (.TagSet // []) as $tags |
      ($targets - [ $tags[].Key ]) |
      join(" ")
    ')

    if [ -n "$MISSING" ]; then
        echo "S3 [$bucket] is missing tags: $MISSING"
    fi
done

echo "================================================================================"
echo "Audit complete."
