#!/bin/bash

# Script to fetch and display logs of the most recent failed GitHub workflow run.
# Requires GITHUB_TOKEN environment variable.
# Usage: ./gh_workflow_failure_logs.sh <owner/repo> <workflow_id_or_filename>

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> <workflow_id_or_filename>"
    echo "  owner/repo: e.g., 'octocat/hello-world'"
    echo "  workflow_id_or_filename: The ID or filename (e.g., 'ci.yml') of the workflow"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
for tool in curl jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

# Check for token
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    exit 1
fi

if [ "$#" -ne 2 ]; then
    usage
fi

REPO=$1
WORKFLOW=$2

echo "Fetching last failed run for $WORKFLOW in $REPO..."

# Use curl config file via stdin to prevent leaking GITHUB_TOKEN in process lists (ps).
# We must escape backslashes and double quotes for the curl config parser to prevent
# configuration injection if a variable contains malicious characters.
ESCAPED_TOKEN=$(echo "$GITHUB_TOKEN" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Get the latest failed run ID
RUN_ID=$(printf "header = \"Authorization: Bearer %s\"\n" "$ESCAPED_TOKEN" | \
    curl -s -K- "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW/runs?status=failure&per_page=1" \
    | jq -r '.workflow_runs[0].id')

if [ "$RUN_ID" == "null" ] || [ -z "$RUN_ID" ]; then
    echo "No failed runs found for this workflow."
    exit 0
fi

echo "Found failed run ID: $RUN_ID. Fetching jobs..."

# Get jobs data for the failed run once
JOBS_DATA=$(printf "header = \"Authorization: Bearer %s\"\n" "$ESCAPED_TOKEN" | \
    curl -s -K- "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/jobs")

# Extract IDs and names of failed jobs
# We use a custom separator to handle job names with spaces
FAILED_JOBS=$(echo "$JOBS_DATA" | jq -r '.jobs[] | select(.conclusion=="failure") | "\(.id)|\(.name)"')

echo "$FAILED_JOBS" | while IFS='|' read -r JOB_ID JOB_NAME; do
    [ -z "$JOB_ID" ] && continue

    echo "---------------------------------------------------------"
    echo "Logs for Job: $JOB_NAME (ID: $JOB_ID)"
    echo "---------------------------------------------------------"

    # Fetch logs for the job
    printf "header = \"Authorization: Bearer %s\"\n" "$ESCAPED_TOKEN" | \
        curl -s -K- -L "https://api.github.com/repos/$REPO/actions/jobs/$JOB_ID/logs"

    echo ""
done

echo "---------------------------------------------------------"
echo "Done."
