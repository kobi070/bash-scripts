#!/bin/bash
set -euo pipefail

# This script initializes a local git repository.
# Usage: ./init_repo.sh [branch_name] (default: main)

BRANCH_NAME=${1:-main}

git init
git checkout -b "$BRANCH_NAME"
git branch
