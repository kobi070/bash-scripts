#!/bin/bash
set -euo pipefail

# This script lists all Azure VMs in the current subscription in a table format.

if ! command -v az >/dev/null 2>&1; then
    echo "Error: Azure CLI (az) is not installed."
    exit 1
fi

# Check if logged in
if ! az account show >/dev/null 2>&1; then
    echo "Error: Not logged into Azure. Please run 'az login'."
    exit 1
fi

echo "Listing all VMs in the current subscription:"
az vm list -o table
