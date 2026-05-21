#!/bin/bash

# Script to analyze a Terraform state file (or output of tf show -json) to provide a summary of resource types and counts.
# Useful for understanding infrastructure scale and complexity.
# Usage: ./tf_resource_stats.sh [state_file]
# Example: ./tf_resource_stats.sh terraform.tfstate

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [state_file]"
    echo "  state_file: (optional) The Terraform state file (JSON) to analyze. Default: terraform.tfstate"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

STATE_FILE="${1:-terraform.tfstate}"

if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file '$STATE_FILE' not found."
    exit 1
fi

echo "Analyzing Terraform state: $STATE_FILE"
echo "--------------------------------------------------------------------------------"
printf "%-50s %-10s\n" "RESOURCE TYPE" "COUNT"
echo "--------------------------------------------------------------------------------"

# Extract resource types and count them
# Works for both .tfstate and 'terraform show -json' output
jq -r '
  if .resources then
    .resources[].type
  elif .values.root_module.resources then
    .values.root_module.resources[].type
  else
    empty
  end
' "$STATE_FILE" | sort | uniq -c | sort -nr | while read -r count type; do
    printf "%-50s %-10s\n" "$type" "$count"
done

echo "--------------------------------------------------------------------------------"
TOTAL=$(jq -r '
  if .resources then
    .resources | length
  elif .values.root_module.resources then
    .values.root_module.resources | length
  else
    0
  end
' "$STATE_FILE")

printf "%-50s %-10s\n" "TOTAL RESOURCES" "$TOTAL"
