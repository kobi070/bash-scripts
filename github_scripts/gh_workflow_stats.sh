#!/bin/bash

# Script to analyze recent GitHub Actions workflow runs for success rate and average duration.
# Part of the Bolt philosophy: Cache API response and use jq for calculations.
# Usage: ./gh_workflow_stats.sh <owner/repo> <workflow_id_or_filename> [limit]
# Example: ./gh_workflow_stats.sh myorg/myrepo main.yml 20

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <owner/repo> <workflow_id_or_filename> [limit]"
    echo "  owner/repo: Repository in format 'owner/repo'"
    echo "  workflow: Workflow ID or filename (e.g., main.yml)"
    echo "  limit: (optional) Number of recent runs to analyze. Default: 10"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 2 ]]; then
    usage
fi

# Check for required tools
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

REPO=$1
WORKFLOW=$2
LIMIT=${3:-10}

# Security Pattern: validate numeric input
if [[ ! "$LIMIT" =~ ^[0-9]+$ ]]; then
    echo "Error: limit must be a positive integer."
    exit 1
fi

echo "Fetching last $LIMIT runs for workflow '$WORKFLOW' in '$REPO'..."

# Bolt optimization: Cache the API response in a variable
RUNS_JSON=$(gh api "repos/$REPO/actions/workflows/$WORKFLOW/runs?per_page=$LIMIT")

# Check if we got any runs
RUN_COUNT=$(echo "$RUNS_JSON" | jq '.workflow_runs | length')

if [ "$RUN_COUNT" -eq 0 ]; then
    echo "No runs found for workflow '$WORKFLOW'."
    exit 0
fi

echo "Analyzing $RUN_COUNT runs..."

# Use jq to calculate statistics
# We calculate:
# - Success rate (%)
# - Average duration (seconds)
# - Max duration (seconds)
# - Min duration (seconds)
STATS=$(echo "$RUNS_JSON" | jq -r '
  .workflow_runs |
  [ .[] | select(.status == "completed") ] as $completed |
  ($completed | length) as $total |
  if $total == 0 then
    "0\t0\t0\t0"
  else
    ($completed | map(select(.conclusion == "success")) | length) as $successes |
    ($successes / $total * 100 | round) as $rate |

    # Calculate durations
    [ $completed[] |
      (.updated_at | fromdate) - (.run_started_at | fromdate)
    ] as $durations |

    ($durations | add / $total | round) as $avg |
    ($durations | max) as $max |
    ($durations | min) as $min |

    "\($rate)\t\($avg)\t\($max)\t\($min)"
  end
')

IFS=$'\t' read -r success_rate avg_dur max_dur min_dur <<< "$STATS"

echo "--------------------------------------------------------------------------------"
echo "Workflow: $WORKFLOW"
echo "Runs Analyzed: $RUN_COUNT"
echo "Success Rate:  $success_rate%"
echo "Avg Duration:  ${avg_dur}s"
echo "Max Duration:  ${max_dur}s"
echo "Min Duration:  ${min_dur}s"
echo "--------------------------------------------------------------------------------"

# Detailed list of recent runs
echo "Recent Runs:"
echo "$RUNS_JSON" | jq -r '
  .workflow_runs[] |
  "\(.created_at) \(.conclusion // .status) \(.html_url)"
' | head -n "$LIMIT"
