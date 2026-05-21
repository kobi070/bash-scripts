#!/bin/bash

# Script to audit S3 buckets for public access block settings and policy status.
# Useful for identifying potentially exposed buckets.
# Usage: ./aws_s3_public_access_audit.sh [profile]
# Example: ./aws_s3_public_access_audit.sh default

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [profile]"
    echo "  profile: (optional) The AWS CLI profile to use."
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

PROFILE_ARG=""
if [ "$#" -ge 1 ]; then
    PROFILE_ARG="--profile $1"
fi

echo "Auditing S3 buckets for public access settings..."
echo "--------------------------------------------------------------------------------------------------------------------"
printf "%-40s %-20s %-20s %-20s\n" "BUCKET NAME" "PUBLIC ACCESS BLOCK" "POLICY STATUS" "ACCOUNT LEVEL"
echo "--------------------------------------------------------------------------------------------------------------------"

# Get account level public access block
ACCOUNT_PAB=$(aws s3api get-public-access-block $PROFILE_ARG 2>/dev/null || echo "Not Set")
if [ "$ACCOUNT_PAB" != "Not Set" ]; then
    ACCOUNT_PAB_SUMMARY=$(echo "$ACCOUNT_PAB" | jq -r '.PublicAccessBlockConfiguration | [.BlockPublicAcls, .IgnorePublicAcls, .BlockPublicPolicy, .RestrictPublicBuckets] | all' | sed 's/true/Restricted/;s/false/Partial/')
else
    ACCOUNT_PAB_SUMMARY="NOT CONFIGURED"
fi

# List buckets
BUCKETS=$(aws s3api list-buckets $PROFILE_ARG --query "Buckets[].Name" --output text)

for bucket in $BUCKETS; do
    # Get bucket public access block
    PAB=$(aws s3api get-public-access-block --bucket "$bucket" $PROFILE_ARG 2>/dev/null || echo "Not Set")
    if [ "$PAB" != "Not Set" ]; then
        PAB_STATUS=$(echo "$PAB" | jq -r '.PublicAccessBlockConfiguration | [.BlockPublicAcls, .IgnorePublicAcls, .BlockPublicPolicy, .RestrictPublicBuckets] | all' | sed 's/true/Restricted/;s/false/Partial/')
    else
        PAB_STATUS="NOT SET"
    fi

    # Get bucket policy status
    POLICY_STATUS=$(aws s3api get-bucket-policy-status --bucket "$bucket" $PROFILE_ARG 2>/dev/null || echo "No Policy")
    if [ "$POLICY_STATUS" != "No Policy" ]; then
        IS_PUBLIC=$(echo "$POLICY_STATUS" | jq -r '.PolicyStatus.IsPublic')
        if [ "$IS_PUBLIC" == "true" ]; then
            POLICY_STATUS_SUMMARY="PUBLIC"
        else
            POLICY_STATUS_SUMMARY="NOT PUBLIC"
        fi
    else
        POLICY_STATUS_SUMMARY="NO POLICY"
    fi

    printf "%-40s %-20s %-20s %-20s\n" "$bucket" "$PAB_STATUS" "$POLICY_STATUS_SUMMARY" "$ACCOUNT_PAB_SUMMARY"
done
