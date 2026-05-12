#!/bin/bash
set -euo pipefail

# This script configures pip to use JFrog Artifactory.
# Usage: ./jf_python_config.sh <repo_name>

if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI not found."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <repo_name>"
    exit 1
fi

REPO="$1"

echo "Configuring pip for Artifactory repo: $REPO"
"$JF_BIN" pip-config --repo-resolve="$REPO" --repo-deploy="$REPO"
