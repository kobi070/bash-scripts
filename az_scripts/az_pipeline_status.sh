#!/bin/bash
set -euo pipefail

# This script checks the status of Azure DevOps pipelines.
# Usage: ./az_pipeline_status.sh <org_url> <project> <pipeline_name>

if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI ('az') not found."
    exit 1
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <org_url> <project> <pipeline_name>"
    exit 1
fi

ORG=$1
PROJECT=$2
PIPELINE=$3

echo "Fetching status for pipeline '$PIPELINE' in project '$PROJECT'..."
az pipelines runs list --organization "$ORG" --project "$PROJECT" --pipeline-ids $(az pipelines list --organization "$ORG" --project "$PROJECT" --name "$PIPELINE" --query "[0].id" -o tsv) --query "[0].{Status:status, Result:result, Finished:finishTime}" -o table
