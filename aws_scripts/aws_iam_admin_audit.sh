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

# Bolt optimization: Use O(1) get-account-authorization-details to fetch all auth data in a single call.
# This reduces API calls from O(G) to O(1), where G is the number of admin groups.
# All filtering and formatting is consolidated into a single jq pipeline to minimize process forks.
aws iam get-account-authorization-details --filter User Group --output json | jq -r --arg arn "$ADMIN_POLICY_ARN" '
  . as $root |
  (.UserDetailList // []) as $users |
  (.GroupDetailList // []) as $groups |

  [ $users[] | select(.AttachedManagedPolicies[]?.PolicyArn == $arn) | .UserName ] as $direct_admins |
  [ $groups[] | select(.AttachedManagedPolicies[]?.PolicyArn == $arn) | .GroupName ] as $admin_groups |

  "Searching for Users with direct AdministratorAccess...",
  (if ($direct_admins | length) == 0 then "  None found." else ($direct_admins[] | "  - \(.)") end),
  "",
  "Searching for Groups with AdministratorAccess...",
  (if ($admin_groups | length) == 0 then "  None found." else ($admin_groups[] | "  - \(.)") end),
  (if ($admin_groups | length) > 0 then
    "",
    "Checking users within these groups...",
    ($admin_groups[] | . as $g |
      "  Group: \($g)",
      ([ $users[] | select(.GroupList[]? == $g) | .UserName ] | if length == 0 then empty else .[] | "    - \(.)" end)
    )
  else
    empty
  end)
'

echo "-------------------------------------------"
echo "Audit complete."
