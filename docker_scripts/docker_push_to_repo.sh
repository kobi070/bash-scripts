#!/bin/bash

# Script to build and push a Docker image to Docker Hub.
# Prioritizes DOCKER_USERNAME and DOCKER_PASSWORD environment variables for login.
# Usage: ./docker_push_to_repo.sh [image_name] [tag] [docker_repo]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [image_name] [tag] [docker_repo]"
    echo "  image_name: (optional) The name of the image. Default: my-image"
    echo "  tag: (optional) The tag to use. Default: latest"
    echo "  docker_repo: (optional) The Docker Hub repository (e.g., username/repo). Default: uses DOCKER_USERNAME if set"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH." >&2
    exit 1
fi

# Variables
IMAGE_NAME=${1:-"my-image"}
TAG=${2:-"latest"}
DEFAULT_REPO="${DOCKER_USERNAME:-mydockerhubusername}/$IMAGE_NAME"
DOCKER_REPO=${3:-$DEFAULT_REPO}

# Check if login is required
# Optimization: Consolidated grep and awk into a single awk command to reduce process forking.
if [ -z "$(docker info | awk '/Username: / {print $2}')" ]; then
    echo "You are not logged in to Docker Hub. Attempting login..."

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
        echo "Error: DockerHub username and password are required for login."
        exit 1
    fi

    # Secure login: Use printf to avoid trailing newline and pipe to stdin
    printf "%s" "$PASSWORD" | docker login -u "$USERNAME" --password-stdin
    unset PASSWORD
fi

# Build the Docker image
echo "Building the Docker image..."
docker build -t "$DOCKER_REPO:$TAG" .

# Push the Docker image
echo "Pushing the image to Docker Hub..."
docker push "$DOCKER_REPO:$TAG"

echo "✅ Docker image pushed successfully: $DOCKER_REPO:$TAG"
