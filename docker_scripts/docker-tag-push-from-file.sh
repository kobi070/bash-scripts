#!/bin/bash

# This script tags and pushes a Docker image to a specified repository.
# Usage: ./docker-tag-push.sh <Dockerfile> <tag> <repository>
# Example: ./docker-tag-push.sh Dockerfile latest my-repo/my-image
# Check if the correct number of arguments is provided

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <image_name> <tag> <repository>"
    exit 1
fi  

# Assign arguments to variables
DOCKER_FILE=$1
TAG=$2
REPOSITORY=$3

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if the image exists
if ! docker image inspect "$IMAGE_NAME:$TAG" > /dev/null 2>&1; then
    echo "Image $IMAGE_NAME:$TAG does not exist. Please check the image name and tag."
    exit 1
fi

# Tag the image
echo "Tagging image $IMAGE_NAME:$TAG as $REPOSITORY:$TAG..."
docker tag "$IMAGE_NAME:$TAG" "$REPOSITORY:$TAG"
if [ $? -ne 0 ]; then
    echo "Failed to tag image $IMAGE_NAME:$TAG."
    exit 1
fi

# Push the image to the repository
echo "Pushing image $REPOSITORY:$TAG to the repository..."
docker push "$REPOSITORY:$TAG"

if [ $? -ne 0 ]; then
    echo "Failed to push image $REPOSITORY:$TAG."
    exit 1
fi

echo "Image $REPOSITORY:$TAG pushed successfully."

# Check if the image was pushed successfully
if docker image inspect "$REPOSITORY:$TAG" > /dev/null 2>&1; then
    echo "Image $REPOSITORY:$TAG is available in the repository."
else
    echo "Image $REPOSITORY:$TAG was not found in the repository after push."
    exit 1
fi