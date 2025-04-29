#!/bin/bash

# This script builds, tags, and pushes a Docker image to a specified repository.
# Usage: ./docker-tag-push.sh <Dockerfile> <tag> <repository>
# Example: ./docker-tag-push.sh Dockerfile latest my-repo/my-image

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <Dockerfile> <tag> <repository>"
    exit 1
fi  

# Assign arguments to variables
DOCKERFILE=$1
TAG=$2
REPOSITORY=$3

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo "Dockerfile $DOCKERFILE does not exist."
    exit 1
fi

# Build image from Dockerfile
IMAGE_NAME=temp-build-image

echo "Building Docker image from $DOCKERFILE..."
docker build -f "$DOCKERFILE" -t "$IMAGE_NAME:$TAG" .

if [ $? -ne 0 ]; then
    echo "Failed to build image from $DOCKERFILE."
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
