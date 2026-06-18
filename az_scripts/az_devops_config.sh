#!/bin/bash

# Script to configure Azure DevOps CLI with Organization URL and Personal Access Token (PAT).
# Useful for initializing Azure DevOps CLI in CI/CD environments.
# Usage: ./az_devops_config.sh <org_url> [pat]
# Example: ./az_devops_config.sh https://dev.azure.com/my-org/
# Note: Recommends using AZ_DEVOPS_PAT environment variable for the PAT to avoid exposure.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <org_url> [pat]"
    echo "  org_url: The Azure DevOps Organization URL (e.g., https://dev.azure.com/my-org/)"
    echo "  pat: (optional) Personal Access Token. Can also be set via AZ_DEVOPS_PAT env var."
    echo "       WARNING: Passing PAT as an argument is insecure and may leak in process lists."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v az &> /dev/null; then
    echo "Error: azure-cli (az) is not installed or not in PATH." >&2
    exit 1
fi

# Input validation: Exactly 1 or 2 arguments allowed
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

ORG_URL=$1

# Security validation: Basic URL format check for ORG_URL
# Supports ports for on-premise installations
if [[ ! "$ORG_URL" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
    echo "Error: Invalid Organization URL format: $ORG_URL" >&2
    exit 1
fi

# Credential selection: Argument overrides Environment variable (standard CLI behavior)
PAT="${AZ_DEVOPS_PAT:-}"
if [ -n "${2:-}" ]; then
    echo "WARNING: Passing Personal Access Token as a command-line argument is insecure."
    echo "It is visible in the system's process list. Use the AZ_DEVOPS_PAT environment variable instead."
    PAT=$2
fi

if [ -z "$PAT" ]; then
    echo "Error: Personal Access Token (PAT) must be provided via AZ_DEVOPS_PAT environment variable or as the second argument." >&2
    exit 1
fi

echo "Configuring Azure DevOps CLI..."

# Install Azure DevOps extension if not present
if ! az extension show --name azure-devops &> /dev/null; then
    echo "Installing azure-devops extension..."
    az extension add --name azure-devops
fi

# Login using PAT securely via stdin
# Using printf to avoid trailing newlines and secret exposure in process lists.
printf "%s" "$PAT" | az devops login --organization "$ORG_URL"

# Set default organization
az devops configure --defaults organization="$ORG_URL"

echo "Success: Azure DevOps CLI configured for $ORG_URL."
