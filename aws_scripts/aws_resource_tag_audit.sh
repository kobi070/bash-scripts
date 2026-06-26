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

# Bolt optimization: Consolidate S3 tag auditing into a single batch API call for all buckets.
# This reduces process forks from O(N) to O(Pages), where N is the number of buckets.
# We join the full bucket list with the tagging API results to catch buckets with NO tags.
BUCKETS_JSON=$(aws s3api list-buckets --query 'Buckets[*].Name' --output json)

# Fetch all tagged S3 buckets, handling pagination explicitly.
TAGS_JSON="[]"
NEXT_TOKEN=""
while :; do
    RESPONSE=$(aws resourcegroupstaggingapi get-resources --resource-type-filters s3:bucket $REGION_ARG ${NEXT_TOKEN:+--pagination-token "$NEXT_TOKEN"} --output json)
    TAGS_JSON=$(echo "$TAGS_JSON" "$RESPONSE" | jq -s '.[0] + (.[1].ResourceTagMappingList // [])')
    NEXT_TOKEN=$(echo "$RESPONSE" | jq -r '.PaginationToken // empty')
    [[ -z "$NEXT_TOKEN" || "$NEXT_TOKEN" == "null" ]] && break
done

echo "$BUCKETS_JSON" | jq -r --argjson tags_data "$TAGS_JSON" --argjson targets "$TARGETS_JSON" '
  # Bolt optimization: Create a map of ARN to Tags for O(1) lookup
  # Using reduce for better compatibility with older jq versions (<1.5)
  ($tags_data | reduce .[] as $item ({}; .[$item.ResourceARN] = $item.Tags)) as $tags_map |
  .[] | . as $bucket |
  "arn:aws:s3:::\($bucket)" as $arn |
  # Retrieve tags from map
  ($tags_map[$arn] // []) as $tags |
  # Calculate missing mandatory tags
  ($targets - [ $tags[].Key ]) as $missing |
  select(($missing | length) > 0) |
  "\($bucket)\t\($missing | join(" "))"
' | while IFS=$'\t' read -r bucket missing; do
    echo "S3 [$bucket] is missing tags: $missing"
done

echo "================================================================================"
echo "Audit complete."
