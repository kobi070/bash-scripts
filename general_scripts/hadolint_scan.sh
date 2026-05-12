#!/bin/bash

# Script to scan a Dockerfile using Hadolint (via Docker) to ensure best practices.
# Useful for CI pipelines to catch common Dockerfile issues.
# Usage: ./hadolint_scan.sh <dockerfile_path>
# Example: ./hadolint_scan.sh ./Dockerfile

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <dockerfile_path>"
    echo "  dockerfile_path: The path to the Dockerfile to scan"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -ne 1 ]; then
    usage
fi

DOCKERFILE=$1

if [ ! -f "$DOCKERFILE" ]; then
    echo "Error: Dockerfile '$DOCKERFILE' not found."
    exit 1
fi

echo "Scanning $DOCKERFILE with Hadolint..."

# Run hadolint using its official Docker image
docker run --rm -i hadolint/hadolint < "$DOCKERFILE" || {
    echo "Warning: Hadolint found issues in $DOCKERFILE."
    exit 1
}

echo "Success: $DOCKERFILE passed Hadolint scan."
