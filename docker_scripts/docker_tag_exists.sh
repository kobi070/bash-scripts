#!/bin/bash

# Script to check if a Docker tag exists in a remote registry without pulling the image.
# Useful for CI/CD pipelines to avoid unnecessary builds or to verify image availability.
# Usage: ./docker_tag_exists.sh <image_name> <tag>
# Example: ./docker_tag_exists.sh library/nginx latest

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name> <tag>"
    echo "  image_name: name of the image (e.g., library/nginx)"
    echo "  tag: image tag (e.g., latest)"
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
if [ "$#" -ne 2 ]; then
    usage
fi

IMAGE_NAME=$1
TAG=$2

echo "Checking if $IMAGE_NAME:$TAG exists in remote registry..."

# Use docker manifest inspect to check for tag existence without pulling
if docker manifest inspect "$IMAGE_NAME:$TAG" > /dev/null 2>&1; then
    echo "Success: Image $IMAGE_NAME:$TAG exists."
    exit 0
else
    echo "Error: Image $IMAGE_NAME:$TAG does not exist or is not accessible."
    exit 1
fi
