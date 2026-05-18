#!/bin/bash

# Script to check if a local Docker image exceeds a specified size limit.
# Useful for CI pipelines to ensure images remain within optimized limits.
# Usage: ./docker_image_size.sh <image_name> <tag> <max_size_mb>
# Example: ./docker_image_size.sh nginx latest 200

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name> <tag> <max_size_mb>"
    echo "  image_name: Name of the Docker image"
    echo "  tag: Image tag"
    echo "  max_size_mb: Maximum allowed size in Megabytes (MB)"
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
if [ "$#" -ne 3 ]; then
    usage
fi

IMAGE=$1
TAG=$2
MAX_SIZE=$3

# Security check: Ensure MAX_SIZE is a numeric integer to prevent shell arithmetic injection
if [[ ! "$MAX_SIZE" =~ ^[0-9]+$ ]]; then
    echo "Error: MAX_SIZE must be a positive numeric integer."
    exit 1
fi

echo "Checking size of $IMAGE:$TAG..."

# Get image size in bytes
SIZE_BYTES=$(docker image inspect "$IMAGE:$TAG" --format='{{.Size}}' 2>/dev/null || true)

if [ -z "$SIZE_BYTES" ]; then
    echo "Error: Image $IMAGE:$TAG not found locally."
    exit 1
fi

# Convert to MB (using integer division)
SIZE_MB=$((SIZE_BYTES / 1024 / 1024))

echo "Current image size: ${SIZE_MB}MB"
echo "Maximum allowed size: ${MAX_SIZE}MB"

if [ "$SIZE_MB" -gt "$MAX_SIZE" ]; then
    echo "Error: Image size exceeds the limit of ${MAX_SIZE}MB."
    exit 1
else
    echo "Success: Image size is within the limit."
    exit 0
fi
