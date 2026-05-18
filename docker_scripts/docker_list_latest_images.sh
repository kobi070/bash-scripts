#!/bin/bash
# docker_list_latest_images.sh - Lists local Docker images using the 'latest' tag.

set -euo pipefail

usage() {
    echo "Usage: $0"
    echo "  -h, --help  Display this help message"
    exit 1
}

if [[ $# -gt 0 && ($1 == "-h" || $1 == "--help") ]]; then
    usage
fi

# Verify dependencies
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed."
    exit 1
fi

echo "Scanning local Docker images for the 'latest' tag..."

# Get images with 'latest' tag
# We use docker images with a filter for the tag
LATEST_IMAGES=$(docker images --filter "reference=*:latest" --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}" || true)

# Count the lines, excluding the header
COUNT=$(echo "$LATEST_IMAGES" | grep -v "REPOSITORY" | grep -c "latest" || true)

if [[ $COUNT -eq 0 ]]; then
    echo "No images found with the 'latest' tag. Good job!"
else
    echo "Found $COUNT images using the 'latest' tag:"
    echo "--------------------------------------------------------------------------------"
    echo "$LATEST_IMAGES"
    echo "--------------------------------------------------------------------------------"
    echo "Warning: Using the 'latest' tag is generally discouraged in production because"
    echo "it makes it difficult to track which version of an image is being used and can"
    echo "lead to inconsistent environments. Consider using specific version tags."
fi
