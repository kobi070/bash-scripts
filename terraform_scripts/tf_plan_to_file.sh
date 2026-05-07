#!/bin/bash
set -euo pipefail

# This script runs terraform plan and saves both the binary plan and a readable text version.

if ! command -v terraform >/dev/null 2>&1; then
    echo "Error: terraform is not installed."
    exit 1
fi

PLAN_FILE="tfplan"
TEXT_PLAN="tfplan.txt"

echo "Running terraform plan..."
terraform plan -out="$PLAN_FILE"

echo "Generating readable text plan..."
terraform show -no-color "$PLAN_FILE" > "$TEXT_PLAN"

echo "✅ Plan saved to $PLAN_FILE and $TEXT_PLAN"
