#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Variables
IMAGE_NAME="my-image"
TAG="latest"
DOCKER_REPO="mydockerhubusername/$IMAGE_NAME"

# Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed." >&2
    exit 1
fi

# Check if login is required
# Optimization: Consolidated grep and awk into a single awk command to reduce process forking.
if [ -z "$(docker info | awk '/Username: / {print $2}')" ]; then
    echo "You are not logged in to Docker Hub."
    read -p "Enter DockerHub Username: " username
    read -s -p "Enter DockerHub Password: " password
    echo
    echo "$password" | docker login -u "$username" --password-stdin
    unset password
fi


# Build the Docker image
echo "Building the Docker image..."
docker build -t "$DOCKER_REPO:$TAG" .

# Push the Docker image
echo "Pushing the image to Docker Hub..."
docker push "$DOCKER_REPO:$TAG"

echo "✅ Docker image pushed successfully: $DOCKER_REPO:$TAG"
