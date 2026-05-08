#!/bin/bash

# Script to wait for an Azure DevOps pipeline run to complete and report its status.
# Usage: ./az_devops_wait_pipeline.sh <project_name> <run_id> [timeout] [interval]
# Example: ./az_devops_wait_pipeline.sh "My Project" 12345 600 30

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <project_name> <run_id> [timeout] [interval]"
    echo "  project_name: The name of the Azure DevOps project"
    echo "  run_id: The ID of the pipeline run"
    echo "  timeout: (optional) Maximum wait time in seconds. Default: 600"
    echo "  interval: (optional) Time between checks in seconds. Default: 30"
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
RUN_ID=$2
TIMEOUT=${3:-600}
INTERVAL=${4:-30}

echo "Waiting for pipeline run $RUN_ID in project $PROJECT_NAME to complete..."

START_TIME=$(date +%s)
END_TIME=$((START_TIME + TIMEOUT))

while [ $(date +%s) -lt $END_TIME ]; do
    RUN_STATUS_JSON=$(az pipelines build show --id "$RUN_ID" --project "$PROJECT_NAME" --output json)

    # Extract status and result
    # Status can be: 'inProgress', 'completed', 'cancelling', 'postponed', 'notStarted'
    STATUS=$(echo "$RUN_STATUS_JSON" | grep -oP '"status": "\K[^"]+' | head -n 1)
    RESULT=$(echo "$RUN_STATUS_JSON" | grep -oP '"result": "\K[^"]+' | head -n 1 || echo "pending")

    if [ "$STATUS" == "completed" ]; then
        echo "Pipeline run $RUN_ID completed with result: $RESULT"
        if [ "$RESULT" == "succeeded" ]; then
            exit 0
        else
            exit 1
        fi
    fi

    echo "Current status: $STATUS. Retrying in ${INTERVAL}s..."
    sleep "$INTERVAL"
done

echo "Error: Timed out waiting for pipeline run $RUN_ID after ${TIMEOUT}s."
exit 1
