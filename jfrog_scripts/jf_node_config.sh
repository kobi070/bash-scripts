#!/bin/bash
set -euo pipefail

# This script configures npm to use JFrog Artifactory.
# Usage: ./jf_node_config.sh <repo_name>

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

echo "Configuring npm for Artifactory repo: $REPO"
"$JF_BIN" npm-config --repo-resolve="$REPO" --repo-deploy="$REPO"
