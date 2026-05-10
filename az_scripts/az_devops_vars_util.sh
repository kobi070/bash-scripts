#!/bin/bash
# az_devops_vars_util.sh
# Utility to manage Azure DevOps Variable Groups via CLI

set -euo pipefail

usage() {
    echo "Usage: $0 [list|show|create|update] [group_name] [project_name] [org_url]"
    echo "Example: $0 list my-project https://dev.azure.com/my-org"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

case $COMMAND in
    list)
        PROJECT=$2
        ORG=$3
        az pipelines variable-group list --project "$PROJECT" --org "$ORG" --output table
        ;;
    show)
        GROUP=$2
        PROJECT=$3
        ORG=$4
        az pipelines variable-group show --group-id "$(az pipelines variable-group list --project "$PROJECT" --org "$ORG" --query "[?name=='$GROUP'].id" -o tsv)" --project "$PROJECT" --org "$ORG"
        ;;
    *)
        echo "Command not implemented yet"
        usage
        ;;
esac
