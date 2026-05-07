#!/bin/bash
set -euo pipefail

# This script is a master cleanup script that runs all Docker cleanup operations.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting full Docker cleanup..."

# Clean containers
if [ -f "$SCRIPT_DIR/clean_docker_ps.sh" ]; then
    bash "$SCRIPT_DIR/clean_docker_ps.sh"
fi

# Clean images
if [ -f "$SCRIPT_DIR/clean_docker_images.sh" ]; then
    bash "$SCRIPT_DIR/clean_docker_images.sh"
fi

# Prune volumes
if [ -f "$SCRIPT_DIR/docker-vol-prune.sh" ]; then
    bash "$SCRIPT_DIR/docker-vol-prune.sh"
fi

# Prune networks
if [ -f "$SCRIPT_DIR/docker-net-prune.sh" ]; then
    bash "$SCRIPT_DIR/docker-net-prune.sh"
fi

echo "✅ Full Docker cleanup complete."
