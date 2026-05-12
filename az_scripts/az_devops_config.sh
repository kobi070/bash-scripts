#!/bin/bash

# Script to configure Azure DevOps CLI with Organization URL and Personal Access Token (PAT).
# Useful for initializing Azure DevOps CLI in CI/CD environments.
# Usage: ./az_devops_config.sh <org_url> [pat]
# Example: ./az_devops_config.sh https://dev.azure.com/my-org/ my-long-pat-token
# Note: Recommends using AZ_DEVOPS_PAT environment variable for the PAT to avoid exposure.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <org_url> [pat]"
    echo "  org_url: The Azure DevOps Organization URL"
    echo "  pat: (optional) Personal Access Token. Can also be set via AZ_DEVOPS_PAT env var."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v az &> /dev/null; then
    echo "Error: azure-cli (az) is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

ORG_URL=$1
# Prefer argument, fallback to environment variable
PAT=${2:-${AZ_DEVOPS_PAT:-}}

if [ -z "$PAT" ]; then
    echo "Error: Personal Access Token (PAT) must be provided as the second argument or via AZ_DEVOPS_PAT environment variable."
    exit 1
fi

echo "Configuring Azure DevOps CLI..."

# Install Azure DevOps extension if not present
if ! az extension show --name azure-devops &> /dev/null; then
    echo "Installing azure-devops extension..."
    az extension add --name azure-devops
fi

# Login using PAT
echo "$PAT" | az devops login --organization "$ORG_URL"

# Set default organization
az devops configure --defaults organization="$ORG_URL"

echo "Success: Azure DevOps CLI configured for $ORG_URL."
