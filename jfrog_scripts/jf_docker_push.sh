#!/bin/bash
set -euo pipefail

# This script pushes a Docker image to JFrog Artifactory using JFrog CLI.
# Usage: ./jf_docker_push.sh <image_name>:<tag> <target_repo>

if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI not found."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <image_name>:<tag> <target_repo>"
    exit 1
fi

IMAGE="$1"
REPO="$2"

echo "Pushing Docker image $IMAGE to $REPO..."
"$JF_BIN" docker push "$IMAGE" "$REPO"
