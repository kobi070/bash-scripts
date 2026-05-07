#!/bin/bash
set -euo pipefail

if [ -d ".git" ]; then
    echo "Error: Directory is already a git repository."
    exit 1
fi

echo "Initializing new git repository..."
git init
git checkout -b main

echo "✅ Git repository initialized with 'main' branch."
git branch
