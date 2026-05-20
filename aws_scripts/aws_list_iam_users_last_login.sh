#!/bin/bash

# Script to list AWS IAM users and their last login (password usage) or access key usage.
# Helps identify stale IAM accounts for cleanup.
# Bolt optimization: Use AWS Credential Report to reduce API calls from O(N) to O(1).
# Usage: ./aws_list_iam_users_last_login.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0"
    echo "  No arguments required."
    echo "  Note: Requires AWS CLI configured with appropriate permissions."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in aws base64 awk; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

echo "Generating IAM credential report (this may take a few seconds)..."

# Request report generation
# Bolt optimization: We use O(1) credential report instead of O(N) per-user calls.
aws iam generate-credential-report --query 'State' --output text > /dev/null

# Poll for report completion
MAX_ATTEMPTS=10
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    STATE=$(aws iam generate-credential-report --query 'State' --output text)
    if [ "$STATE" == "COMPLETE" ]; then
        break
    fi
    echo "  Report state: $STATE. Waiting..."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ "$STATE" != "COMPLETE" ]; then
    echo "Error: Failed to generate credential report after $MAX_ATTEMPTS attempts."
    exit 1
fi

echo "Fetching activity report..."
echo "--------------------------------------------------------------------------------"
printf "%-30s %-25s %-25s\n" "USER NAME" "PASSWORD LAST USED" "ACCESS KEY LAST USED"
echo "--------------------------------------------------------------------------------"

# Fetch, decode, and parse the report
# CSV columns: user, arn, user_creation_time, password_enabled, password_last_used,
# password_last_changed, password_next_rotation, mfa_active, access_key_1_active,
# access_key_1_last_rotated, access_key_1_last_used_date, access_key_1_last_used_region,
# access_key_1_last_used_service, access_key_2_active, access_key_2_last_rotated,
# access_key_2_last_used_date, access_key_2_last_used_region, access_key_2_last_used_service, ...
# Indices (1-based): user(1), password_last_used(5), access_key_1_last_used_date(11), access_key_2_last_used_date(16)

aws iam get-credential-report --query 'Content' --output text | base64 --decode | awk -F',' '
NR > 1 {
    user = $1
    pass_used = $5
    key1_used = $11
    key2_used = $16

    # Normalize "not_supported", "N/A", "no_information"
    if (pass_used == "not_supported" || pass_used == "N/A" || pass_used == "no_information") pass_used = "Never / Not Set"

    # Calculate latest key usage
    latest_key = "Never"
    if (key1_used != "N/A" && key1_used != "no_information") latest_key = key1_used
    if (key2_used != "N/A" && key2_used != "no_information") {
        if (latest_key == "Never" || key2_used > latest_key) latest_key = key2_used
    }

    printf "%-30s %-25s %-25s\n", user, pass_used, latest_key
}' | sort

echo "--------------------------------------------------------------------------------"
echo "Note: Activity depends on AWS recording events. 'Never' might mean the key/password was never used or usage was not recorded."
