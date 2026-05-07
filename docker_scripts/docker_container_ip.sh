#!/bin/bash
set -euo pipefail

# This script retrieves the IP address of a running Docker container.

usage() {
    echo "Usage: $0 <container_name_or_id>"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

container_id=$1

# Check if the container exists and is running
if ! docker ps -q --no-trunc | grep -q "^$(docker inspect -f '{{.Id}}' "$container_id" 2>/dev/null || echo "non-existent")$"; then
    echo "Error: Container '$container_id' is not running or does not exist."
    exit 1
fi

# Get the IP address
ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")

if [ -z "$ip_address" ]; then
    echo "Container '$container_id' has no IP address (maybe it's using host network?)."
else
    echo "IP Address of '$container_id': $ip_address"
fi
