#!/bin/bash

# Script to log in to Docker Hub.
# Prioritizes DOCKER_USERNAME and DOCKER_PASSWORD environment variables.
# Usage: ./docker_login.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0"
    echo "  Logs in to Docker Hub using DOCKER_USERNAME and DOCKER_PASSWORD environment variables."
    echo "  If variables are not set, it will prompt for them interactively."
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

# Check if login is required
if ! docker info | grep -q 'Username:'; then
    echo "You are not logged in. Attempting login..."
   
    USERNAME=${DOCKER_USERNAME:-}
    PASSWORD=${DOCKER_PASSWORD:-}

    if [ -z "$USERNAME" ]; then
        read -p "Enter DockerHub Username: " USERNAME
    fi

    if [ -z "$PASSWORD" ]; then
        read -s -p "Enter DockerHub Password: " PASSWORD
        echo
    fi

    if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
        echo "Error: DockerHub username and password are required."
        exit 1
    fi

    # Secure login
    echo "$PASSWORD" | docker login -u "$USERNAME" --password-stdin

    unset PASSWORD
fi

echo "✅ You are logged in to Docker Hub."
