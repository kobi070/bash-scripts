#!/bin/bash

# Script to list Azure DevOps pipelines for a given project.
# Usage: ./az_devops_list_pipelines.sh <project_name> [org_url]
# Example: ./az_devops_list_pipelines.sh "My Project"

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <project_name> [org_url]"
    echo "  project_name: The name of the Azure DevOps project"
    echo "  org_url: (optional) The Azure DevOps Organization URL"
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

PROJECT_NAME=$1
ORG_ARG=""
if [ "$#" -ge 2 ]; then
    ORG_ARG="--organization $2"
fi

echo "Listing pipelines for project: $PROJECT_NAME..."

# List pipelines using az devops CLI
az pipelines list --project "$PROJECT_NAME" $ORG_ARG --output table
