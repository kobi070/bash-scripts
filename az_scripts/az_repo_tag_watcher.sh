#!/bin/bash
# az_repo_tag_watcher.sh
# Monitors a repository for new tags and triggers a pipeline if a new tag is found.
# It uses an Azure DevOps Variable Group to store the last seen tag for persistence.

set -euo pipefail

usage() {
    echo "Usage: $0 --org <org_url> --project <project> --repo <repo_name> --pipeline <pipeline_name_or_id> --group <variable_group_name> [--variable <variable_name>]"
    echo ""
    echo "Options:"
    echo "  --org       Azure DevOps Organization URL (e.g., https://dev.azure.com/org)"
    echo "  --project   Project Name"
    echo "  --repo      Repository Name to monitor"
    echo "  --pipeline  Target Pipeline Name or ID to trigger"
    echo "  --group     Variable Group Name to store the state"
    echo "  --variable  (Optional) Variable Name in the group. Defaults to LAST_TAG_<REPO_NAME>"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --org) ORG="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        --pipeline) TARGET_PIPELINE="$2"; shift 2 ;;
        --group) VAR_GROUP="$2"; shift 2 ;;
        --variable) VAR_NAME="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
done

# Validate required arguments
if [[ -z "${ORG:-}" || -z "${PROJECT:-}" || -z "${REPO:-}" || -z "${TARGET_PIPELINE:-}" || -z "${VAR_GROUP:-}" ]]; then
    usage
fi

# Default variable name if not provided
if [[ -z "${VAR_NAME:-}" ]]; then
    # Optimized: Use Bash parameter expansion to sanitize repo name, reducing process forks (echo|sed -> bash builtin)
    CLEAN_REPO="${REPO//[^a-zA-Z0-9]/_}"
    VAR_NAME="LAST_TAG_${CLEAN_REPO}"
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' not found. Please install it to run this script."
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI ('az') not found."
    exit 1
fi

if ! az extension show --name azure-devops &> /dev/null; then
    echo "Error: Azure DevOps extension for CLI not found. Install with: az extension add --name azure-devops"
    exit 1
fi

echo "Checking for new tags in repository: $REPO..."

# 1. Fetch the latest tag from the repository
LATEST_TAG=$(az repos ref list --repository "$REPO" --project "$PROJECT" --organization "$ORG" --filter tags/ --query "[].name" -o tsv | sed 's|refs/tags/||' | sort -V | tail -n 1)

if [[ -z "$LATEST_TAG" ]]; then
    echo "No tags found in repository $REPO. Skipping."
    exit 0
fi

echo "Latest tag found: $LATEST_TAG"

# 2. Get the variable group ID
GROUP_ID=$(az pipelines variable-group list --project "$PROJECT" --organization "$ORG" --query "[?name=='$VAR_GROUP'].id" -o tsv)

if [[ -z "$GROUP_ID" ]]; then
    echo "Error: Variable group '$VAR_GROUP' not found in project '$PROJECT'."
    exit 1
fi

# 3. Get the last seen tag from the variable group
# Note: This assumes the variable exists in the group.
LAST_SEEN_TAG=$(az pipelines variable-group show --group-id "$GROUP_ID" --project "$PROJECT" --organization "$ORG" --query "variables.\"$VAR_NAME\".value" -o tsv)

echo "Last seen tag: ${LAST_SEEN_TAG:-None}"

# 4. Compare tags
if [[ "$LATEST_TAG" != "$LAST_SEEN_TAG" ]]; then
    echo "New tag detected! Triggering pipeline '$TARGET_PIPELINE'..."

    # Optimized: Trigger the pipeline and extract the run ID in a single 'az' call with TSV output.
    # This eliminates two process forks (echo and jq) and avoids storing the full JSON response.
    RUN_ID=$(az pipelines run --name "$TARGET_PIPELINE" --project "$PROJECT" --organization "$ORG" --variables "SOURCE_TAG=$LATEST_TAG" --query "id" --output tsv)

    if [[ -n "$RUN_ID" && "$RUN_ID" != "null" ]]; then
        echo "Successfully triggered pipeline. Run ID: $RUN_ID"

        # 5. Update the variable group with the new tag
        echo "Updating variable group state..."
        if [[ -z "$LAST_SEEN_TAG" ]]; then
            # Create variable if it doesn't exist (this is tricky with CLI, usually update is preferred)
            # Actually variable-group variable create doesn't exist in some versions, but update works if it exists.
            # To be safe, we assume the user pre-created the variable or we try to update.
            az pipelines variable-group variable create --group-id "$GROUP_ID" --name "$VAR_NAME" --value "$LATEST_TAG" --project "$PROJECT" --organization "$ORG" > /dev/null
        else
            az pipelines variable-group variable update --group-id "$GROUP_ID" --name "$VAR_NAME" --value "$LATEST_TAG" --project "$PROJECT" --organization "$ORG" > /dev/null
        fi
        echo "State updated: $VAR_NAME=$LATEST_TAG"
    else
        echo "Error: Failed to trigger pipeline."
        exit 1
    fi
else
    echo "No new tags detected. Repository is up to date."
fi
