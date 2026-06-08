#!/bin/bash

# Script to configure Azure DevOps CLI with Organization URL and Personal Access Token (PAT).
# Useful for initializing Azure DevOps CLI in CI/CD environments.
# Usage: ./az_devops_config.sh <org_url>
# Example: ./az_devops_config.sh https://dev.azure.com/my-org/
# Note: Requires AZ_DEVOPS_PAT environment variable for the PAT to avoid exposure.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <org_url>"
    echo "  org_url: The Azure DevOps Organization URL"
    echo "  Note: Requires AZ_DEVOPS_PAT environment variable for authentication."
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
if [ "$#" -ne 1 ]; then
    usage
fi

ORG_URL=$1

# Security Pattern: Prioritize environment variables for secrets to prevent exposure in process lists.
# Fallback to positional arguments is intentionally removed to align with Sentinel standards.
PAT=${AZ_DEVOPS_PAT:-}

if [ -z "$PAT" ]; then
    echo "Error: AZ_DEVOPS_PAT environment variable is not set."
    echo "Please set it before running this script for secure authentication."
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
