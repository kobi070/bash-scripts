#!/bin/bash

# Script to summarize GitHub Action workflow run statuses for a repository.
# Useful for a quick health check of CI/CD pipelines.
# Usage: ./gh_workflow_stats.sh <owner/repo> [days]
# Example: ./gh_workflow_stats.sh kubernetes/kubernetes 7

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> [days]"
    echo "  owner/repo: The GitHub repository (e.g., argoproj/argo-cd)"
    echo "  days: (optional) How many days back to look. Default: 7"
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

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

REPO=$1
DAYS=${2:-7}

# Portability for date command
if date --version >/dev/null 2>&1; then
    # GNU Date
    SINCE_DATE=$(date -d "$DAYS days ago" --iso-8601=seconds)
else
    # BSD Date (macOS)
    SINCE_DATE=$(date -v-"$DAYS"d +"%Y-%m-%dT%H:%M:%SZ")
fi

echo "Fetching workflow stats for $REPO since $SINCE_DATE..."

# Get workflow runs from GitHub API
API_URL="https://api.github.com/repos/$REPO/actions/runs?per_page=100"

# Use array for arguments to safely handle authentication
ARGS=(-s -H "Accept: application/vnd.github.v3+json")
if [ -n "${GITHUB_TOKEN:-}" ]; then
    ARGS+=(-H "Authorization: token $GITHUB_TOKEN")
fi

RUNS_JSON=$(curl "${ARGS[@]}" "$API_URL")

# Check if we got a valid response
if echo "$RUNS_JSON" | jq -e '.message' >/dev/null 2>&1; then
    MSG=$(echo "$RUNS_JSON" | jq -r '.message')
    echo "Error from GitHub API: $MSG"
    exit 1
fi

echo "--------------------------------------------------------------------------------"
printf "%-30s %-15s %-15s\n" "WORKFLOW" "CONCLUSION" "COUNT"
echo "--------------------------------------------------------------------------------"

# Process runs and aggregate status
echo "$RUNS_JSON" | jq -r --arg since "$SINCE_DATE" '
  .workflow_runs[] |
  select(.created_at >= $since) |
  "\(.name)\t\(.conclusion // "in_progress")"
' | sort | uniq -c | awk '
  {
    count=$1; conclusion=$2;
    # Workflow name can contain spaces, so join all remaining fields
    workflow=""; for(i=3; i<=NF; i++) workflow=(workflow == "" ? $i : workflow" "$i);
    # Actually uniq -c output is "count conclusion workflow..." or similar depending on sorting
    # If we output "workflow\tconclusion" from jq, then uniq -c gives "count workflow conclusion"
    # Wait, my jq output was "name\tconclusion"
    # uniq -c for "CI\tsuccess" gives "   1 CI\tsuccess"
    # So $1 is count, $NF is conclusion, and $2..$(NF-1) is workflow

    conclusion=$NF;
    workflow=$2; for(i=3; i<NF; i++) workflow=workflow" "$i;

    printf "%-30s %-15s %-15s\n", workflow, conclusion, count
  }
'

echo "--------------------------------------------------------------------------------"
TOTAL_RUNS=$(echo "$RUNS_JSON" | jq -r --arg since "$SINCE_DATE" '[.workflow_runs[] | select(.created_at >= $since)] | length')
SUCCESS_RUNS=$(echo "$RUNS_JSON" | jq -r --arg since "$SINCE_DATE" '[.workflow_runs[] | select(.created_at >= $since and .conclusion == "success")] | length')

if [ "$TOTAL_RUNS" -gt 0 ]; then
    # Calculate success rate without bc for better portability
    SUCCESS_RATE=$(( (SUCCESS_RUNS * 100) / TOTAL_RUNS ))
    echo "Total Runs: $TOTAL_RUNS"
    echo "Success Rate: ${SUCCESS_RATE}%"
else
    echo "No runs found in the specified period."
fi
