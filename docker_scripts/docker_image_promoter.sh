#!/bin/bash

# docker_image_promoter.sh - Promotes a Docker image from one registry/tag to another.
# Handles pulling, re-tagging, and pushing in a single command.
# Part of the DevOps Automation Hub.

set -euo pipefail

usage() {
    echo "Usage: $0 <source_image> <dest_image>"
    echo "  source_image: The full source image (e.g., my-registry.com/app:1.0)"
    echo "  dest_image:   The full destination image (e.g., prod-registry.com/app:1.0)"
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if [ "$#" -ne 2 ]; then
    usage
fi

SOURCE=$1
DEST=$2

# Verify dependencies
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed."
    exit 1
fi

echo "Promoting image:"
echo "  Source: $SOURCE"
echo "  Dest:   $DEST"
echo "--------------------------------------------------------------------------------"

echo "Step 1: Pulling source image..."
docker pull "$SOURCE"

echo -e "\nStep 2: Tagging image..."
docker tag "$SOURCE" "$DEST"

echo -e "\nStep 3: Pushing to destination..."
docker push "$DEST"

echo "--------------------------------------------------------------------------------"
echo "Promotion successful!"
