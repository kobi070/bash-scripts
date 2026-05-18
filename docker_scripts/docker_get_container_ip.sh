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

# Optimized: Retrieve container status and IP addresses in a single 'docker inspect' call.
# This reduces up to 5 process forks (docker ps x2, grep x2, sed) into zero additional forks
# by consolidating the running-state check and IP extraction.
# Format: <RunningState>|<IPAddresses>
if ! RESULT=$(docker inspect -f '{{.State.Running}}|{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$CONTAINER" 2>/dev/null); then
    echo "Error: Container '$CONTAINER' does not exist."
    exit 1
fi

# Parse the consolidated result
IFS='|' read -r IS_RUNNING RAW_IP_ADDRESS <<< "$RESULT"

if [[ "$IS_RUNNING" != "true" ]]; then
    echo "Error: Container '$CONTAINER' is not running."
    exit 1
fi

# Trim trailing whitespace using Bash parameter expansion (replaces 'sed' fork)
IP_ADDRESS="${RAW_IP_ADDRESS% }"

if [[ -z "$IP_ADDRESS" ]]; then
    echo "Error: Could not retrieve IP address for '$CONTAINER'. It might be using 'host' network mode or is not connected to a network."
    exit 1
fi

echo "IP Address of '$CONTAINER': $IP_ADDRESS"
