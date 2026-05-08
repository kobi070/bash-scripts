#!/bin/bash
set -euo pipefail

# This script lists all repositories in an Azure DevOps project.
# Usage: ./az_list_repos.sh <org_url> <project>

if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI ('az') not found."
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <org_url> <project>"
    exit 1
fi

ORG=$1
PROJECT=$2

echo "Listing repositories in project '$PROJECT'..."
az repos list --organization "$ORG" --project "$PROJECT" --query "[].{Name:name, ID:id, RemoteUrl:remoteUrl}" -o table
