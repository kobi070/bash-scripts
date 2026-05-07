#!/bin/bash

# Script to trigger an Azure DevOps pipeline run.
# Usage: ./az_devops_run_pipeline.sh <project_name> <pipeline_id_or_name> [branch_name]
# Example: ./az_devops_run_pipeline.sh "My Project" "My Pipeline" main

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <project_name> <pipeline_id_or_name> [branch_name]"
    echo "  project_name: The name of the Azure DevOps project"
    echo "  pipeline_id_or_name: The ID or name of the pipeline"
    echo "  branch_name: (optional) The branch to run the pipeline for"
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
if [ "$#" -lt 2 ]; then
    usage
fi

PROJECT_NAME=$1
PIPELINE=$2
BRANCH=${3:-""}

BRANCH_ARG=""
if [ -n "$BRANCH" ]; then
    BRANCH_ARG="--branch $BRANCH"
fi

echo "Triggering pipeline run for: $PIPELINE in project: $PROJECT_NAME..."

# Run the pipeline
RUN_INFO=$(az pipelines run --name "$PIPELINE" --project "$PROJECT_NAME" $BRANCH_ARG --output json)

RUN_ID=$(echo "$RUN_INFO" | grep -oP '"id": \K\d+' | head -n 1 || echo "")

if [ -n "$RUN_ID" ]; then
    echo "Success: Pipeline run triggered."
    echo "Run ID: $RUN_ID"
    echo "URL: $(echo "$RUN_INFO" | grep -oP '"web": "\K[^"]+')"
else
    echo "Error: Failed to trigger pipeline run."
    echo "$RUN_INFO"
    exit 1
fi
