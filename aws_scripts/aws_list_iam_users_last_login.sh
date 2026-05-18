#!/bin/bash

# Script to list AWS IAM users and their last login (password usage) or access key usage.
# Helps identify stale IAM accounts for cleanup.
# Usage: ./aws_list_iam_users_last_login.sh
# Example: ./aws_list_iam_users_last_login.sh

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
if ! command -v aws &> /dev/null; then
    echo "Error: aws-cli is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

echo "Fetching IAM users and their last activity..."
echo "--------------------------------------------------------------------------------"
printf "%-30s %-25s %-25s\n" "USER NAME" "PASSWORD LAST USED" "ACCESS KEY LAST USED"
echo "--------------------------------------------------------------------------------"

# Get all users
USERS=$(aws iam list-users --query 'Users[*].UserName' --output json)

echo "$USERS" | jq -r '.[]' | while read -r USER; do
    # Get user details for password usage
    PASS_LAST_USED=$(aws iam get-user --user-name "$USER" --query 'User.PasswordLastUsed' --output text)
    if [ "$PASS_LAST_USED" == "None" ]; then
        PASS_LAST_USED="Never / Not Set"
    fi

    # Get access keys and their last usage
    KEYS=$(aws iam list-access-keys --user-name "$USER" --query 'AccessKeyMetadata[*].AccessKeyId' --output json)
    KEY_LAST_USED_FINAL="Never"

    while read -r KEY_ID; do
        if [ -n "$KEY_ID" ] && [ "$KEY_ID" != "null" ]; then
            LAST_USED=$(aws iam get-access-key-last-used --access-key-id "$KEY_ID" --query 'AccessKeyLastUsed.LastUsedDate' --output text)
            if [ "$LAST_USED" != "None" ]; then
                # Keep the most recent one
                if [[ "$KEY_LAST_USED_FINAL" == "Never" ]] || [[ "$LAST_USED" > "$KEY_LAST_USED_FINAL" ]]; then
                    KEY_LAST_USED_FINAL="$LAST_USED"
                fi
            fi
        fi
    done < <(echo "$KEYS" | jq -r '.[]')

    printf "%-30s %-25s %-25s\n" "$USER" "$PASS_LAST_USED" "$KEY_LAST_USED_FINAL"
done

echo "--------------------------------------------------------------------------------"
echo "Note: Activity depends on AWS recording events. 'Never' might mean the key/password was never used or usage was not recorded."
