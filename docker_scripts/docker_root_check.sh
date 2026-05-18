#!/bin/bash

# Script to scan running Docker containers and identify any running as the root user.
# Part of the Sentinel philosophy: Identifying security risks.
# Optimized with Bolt principles: Using docker inspect --format to minimize process forks.
# Usage: ./docker_root_check.sh [--all]
# Example: ./docker_root_check.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [--all]"
    echo "  --all: Check all containers (default: only running ones)"
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

ALL_FLAG=""
if [[ "${1:-}" == "--all" ]]; then
    ALL_FLAG="-a"
fi

echo "Checking containers for root user execution..."

# Bolt optimization: Extract Name and User in a single docker inspect call
# We first get the IDs to avoid issues with formatting multiple containers if none exist
CONTAINER_IDS=$(docker ps $ALL_FLAG -q)

if [ -z "$CONTAINER_IDS" ]; then
    echo "No containers found."
    exit 0
fi

# Use docker inspect to get Name and User.
# User can be empty (defaults to root in many images) or "0" or "root" or "user:group"
# We use a custom delimiter to handle names with spaces (though rare in container names)
ROOT_CONTAINERS=$(docker inspect --format '{{.Name}}|{{.Config.User}}' $CONTAINER_IDS | awk -F'|' '
  {
    name = $1
    user = $2
    # If user is empty, 0, or starts with root, it is considered root
    if (user == "" || user == "0" || user ~ /^root(:|$)/ || user ~ /^0(:|$)/) {
      # Remove leading slash from container name
      gsub(/^\//, "", name)
      print name " (" (user == "" ? "default/root" : user) ")"
    }
  }
')

if [ -z "$ROOT_CONTAINERS" ]; then
    echo "OK: No containers found running as root."
    exit 0
else
    echo "WARNING: The following containers are running as root (or UID 0):"
    echo "$ROOT_CONTAINERS"
    exit 1
fi
