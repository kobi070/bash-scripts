#!/bin/bash

# Script to build and push a Docker image with support for multiple tags.
# Useful for CI/CD pipelines to build once and push to multiple tags (e.g., git-sha and latest).
# Usage: ./docker_build_push.sh <image_name> <tags_comma_separated> [dockerfile_path] [build_context]
# Example: ./docker_build_push.sh my-repo/my-app "v1.0.0,latest" "./Dockerfile" "."

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name> <tags_comma_separated> [dockerfile_path] [build_context]"
    echo "  image_name: The name of the image (without tag)"
    echo "  tags_comma_separated: Comma-separated list of tags (e.g., 'v1.0.1,latest')"
    echo "  dockerfile_path: (optional) Path to the Dockerfile. Default: ./Dockerfile"
    echo "  build_context: (optional) The build context directory. Default: ."
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

# Input validation
if [ "$#" -lt 2 ]; then
    usage
fi

IMAGE_NAME=$1
TAGS=$2
DOCKERFILE=${3:-./Dockerfile}
CONTEXT=${4:-.}

# Split tags into an array
IFS=',' read -ra TAG_ARRAY <<< "$TAGS"

echo "Building Docker image: $IMAGE_NAME with tags: ${TAG_ARRAY[*]}..."

# Build the image with the first tag
FIRST_TAG="${TAG_ARRAY[0]}"
docker build -t "$IMAGE_NAME:$FIRST_TAG" -f "$DOCKERFILE" "$CONTEXT"

# Tag the image for the rest of the tags
for ((i=1; i<${#TAG_ARRAY[@]}; i++)); do
    TAG="${TAG_ARRAY[$i]}"
    echo "Tagging: $IMAGE_NAME:$TAG"
    docker tag "$IMAGE_NAME:$FIRST_TAG" "$IMAGE_NAME:$TAG"
done

# Push all tags
for TAG in "${TAG_ARRAY[@]}"; do
    echo "Pushing: $IMAGE_NAME:$TAG"
    docker push "$IMAGE_NAME:$TAG"
done

echo "Successfully built and pushed all tags for $IMAGE_NAME."
