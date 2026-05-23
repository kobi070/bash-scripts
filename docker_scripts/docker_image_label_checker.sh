#!/bin/bash

# Script to verify the presence of mandatory labels in a local Docker image.
# Usage: ./docker_image_label_checker.sh <image_name> [required_labels]
# Example: ./docker_image_label_checker.sh my-app:latest "maintainer,version,description"

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name> [required_labels]"
    echo "  image_name: The name of the Docker image to inspect."
    echo "  required_labels: (optional) Comma-separated list of labels. Default: maintainer,version"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
    usage
fi

# Check for required tools
for tool in docker jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

IMAGE=$1
LABELS_STR=${2:-"maintainer,version"}
IFS=',' read -ra REQUIRED_LABELS <<< "$LABELS_STR"

echo "Checking mandatory labels for image: $IMAGE"

# Get labels from docker inspect
IMAGE_LABELS=$(docker inspect "$IMAGE" --format='{{json .Config.Labels}}')

if [[ "$IMAGE_LABELS" == "null" ]]; then
    echo "WARNING: Image has NO labels."
    for label in "${REQUIRED_LABELS[@]}"; do
        echo "  [MISSING] $label"
    done
    exit 1
fi

MISSING_COUNT=0
for label in "${REQUIRED_LABELS[@]}"; do
    # Check if label exists in the JSON object
    EXISTS=$(echo "$IMAGE_LABELS" | jq --arg l "$label" 'has($l)')

    if [[ "$EXISTS" == "true" ]]; then
        VALUE=$(echo "$IMAGE_LABELS" | jq -r --arg l "$label" '.[$l]')
        echo "  [FOUND]   $label = $VALUE"
    else
        echo "  [MISSING] $label"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

if [[ $MISSING_COUNT -eq 0 ]]; then
    echo "PASS: All mandatory labels are present."
else
    echo "FAIL: $MISSING_COUNT mandatory label(s) missing."
    exit 1
fi
