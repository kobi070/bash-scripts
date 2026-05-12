#!/bin/bash

# Script to display the layers of a Docker image and their sizes.
# Helps developers identify where image bloat occurs during the build process.
# Usage: ./docker_show_image_layers.sh <image_name>
# Example: ./docker_show_image_layers.sh my-app:latest

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name>"
    echo "  image_name: The name (and optionally tag) of the Docker image"
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
if [ "$#" -lt 1 ]; then
    usage
fi

IMAGE_NAME=$1

# Verify image exists locally
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "Error: Image '$IMAGE_NAME' not found locally."
    exit 1
fi

echo "Displaying layers for image: $IMAGE_NAME"
echo "--------------------------------------------------------------------------------"
printf "%-15s %-15s %s\n" "IMAGE ID" "SIZE" "CREATED BY (Instruction)"
echo "--------------------------------------------------------------------------------"

# Use docker history to get layer information
# --no-trunc to see the full instruction
# awk is used to format the output nicely
docker history --no-trunc --format "{{.ID}}\t{{.Size}}\t{{.CreatedBy}}" "$IMAGE_NAME" | \
    awk -F'\t' '{ printf "%-15s %-15s %s\n", $1, $2, $3 }'

echo "--------------------------------------------------------------------------------"
echo "Done."
