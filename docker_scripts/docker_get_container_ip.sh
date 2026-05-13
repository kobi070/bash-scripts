#!/bin/bash

# Script to retrieve the IP address of a running Docker container.
# Usage: ./docker_get_container_ip.sh <container_name_or_id>
# Example: ./docker_get_container_ip.sh my-nginx

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <container_name_or_id>"
    echo "  container_name_or_id: The name or ID of the Docker container"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Input validation
if [ "$#" -ne 1 ]; then
    usage
fi

CONTAINER=$1

# Check for required tools
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH."
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER}$" && ! docker ps --format '{{.ID}}' | grep -q "^${CONTAINER}"; then
    echo "Error: Container '$CONTAINER' is not running or does not exist."
    exit 1
fi

# Retrieve IP address
# Using a space separator if multiple networks are found
IP_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$CONTAINER" | sed 's/ $//')

if [ -z "$IP_ADDRESS" ]; then
    echo "Error: Could not retrieve IP address for '$CONTAINER'. It might be using 'host' network mode or is not connected to a network."
    exit 1
fi

echo "IP Address of '$CONTAINER': $IP_ADDRESS"
