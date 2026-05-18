#!/bin/bash

# Script to audit AWS IAM users and groups that have AdministratorAccess.
# This follows Sentinel security principles by identifying overly permissive identities.
# Usage: ./aws_iam_admin_audit.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0"
    echo "  Identifies IAM users and groups with the 'AdministratorAccess' policy."
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

ADMIN_POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"

echo "Auditing AWS IAM for AdministratorAccess..."
echo "-------------------------------------------"

# Find entities with the policy directly attached
echo "Searching for Users with direct AdministratorAccess..."
USERS=$(aws iam list-entities-for-policy --policy-arn "$ADMIN_POLICY_ARN" --query 'PolicyUsers[].UserName' --output json)
if [ "$(echo "$USERS" | jq '. | length')" -eq 0 ]; then
    echo "  None found."
else
    echo "$USERS" | jq -r '.[]' | sed 's/^/  - /'
fi

echo ""
echo "Searching for Groups with AdministratorAccess..."
GROUPS=$(aws iam list-entities-for-policy --policy-arn "$ADMIN_POLICY_ARN" --query 'PolicyGroups[].GroupName' --output json)
if [ "$(echo "$GROUPS" | jq '. | length')" -eq 0 ]; then
    echo "  None found."
else
    echo "$GROUPS" | jq -r '.[]' | sed 's/^/  - /'

    echo ""
    echo "Checking users within these groups..."
    for group in $(echo "$GROUPS" | jq -r '.[]'); do
        echo "  Group: $group"
        GROUP_USERS=$(aws iam get-group --group-name "$group" --query 'Users[].UserName' --output json)
        echo "$GROUP_USERS" | jq -r '.[]' | sed 's/^/    - /'
    done
fi

echo "-------------------------------------------"
echo "Audit complete."
