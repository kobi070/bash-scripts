#!/bin/bash

# Script to safely remove unused Docker images, containers, and volumes.
# Supports a dry-run mode to see what would be removed.
# Usage: ./docker_clean_unused.sh [--dry-run]
# Example: ./docker_clean_unused.sh --dry-run

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [--dry-run]"
    echo "  --dry-run: (optional) Only show what would be removed without actually removing it."
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

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "--- DRY RUN MODE: No resources will be deleted ---"
fi

# 1. Stopped containers
echo "Processing unused containers..."
UNUSED_CONTAINERS=$(docker ps -a -q -f status=exited -f status=created)
if [ -n "$UNUSED_CONTAINERS" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Would remove the following containers:"
        docker ps -a -f status=exited -f status=created --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
    else
        echo "Removing unused containers..."
        docker container prune -f
    fi
else
    echo "No unused containers found."
fi

# 2. Dangling images
echo "Processing dangling images..."
DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
if [ -n "$DANGLING_IMAGES" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Would remove the following dangling images:"
        docker images -f "dangling=true" --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}"
    else
        echo "Removing dangling images..."
        docker image prune -f
    fi
else
    echo "No dangling images found."
fi

# 3. Unused volumes
echo "Processing unused volumes..."
UNUSED_VOLUMES=$(docker volume ls -q -f dangling=true)
if [ -n "$UNUSED_VOLUMES" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Would remove the following unused volumes:"
        docker volume ls -f dangling=true
    else
        echo "Removing unused volumes..."
        docker volume prune -f
    fi
else
    echo "No unused volumes found."
fi

# 4. Unused networks
echo "Processing unused networks..."
if [ "$DRY_RUN" = true ]; then
    echo "Would remove unused networks (docker network prune)."
else
    echo "Removing unused networks..."
    docker network prune -f
fi

echo "Docker cleanup process completed."
