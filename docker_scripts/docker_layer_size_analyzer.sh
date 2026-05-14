#!/bin/bash

# Script to analyze Docker image layers and identify size-intensive steps.
# Useful for optimizing Dockerfiles and reducing image size.
# Usage: ./docker_layer_size_analyzer.sh <image_name>
# Example: ./docker_layer_size_analyzer.sh node:18-alpine

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name>"
    echo "  image_name: The name/ID of the Docker image to analyze."
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
if [ "$#" -ne 1 ]; then
    usage
fi

IMAGE=$1

echo "Analyzing layers for image: $IMAGE"
echo "--------------------------------------------------------------------------------"
printf "%-15s %-15s %-50s\n" "IMAGE ID" "SIZE" "CREATED BY (TRUNCATED)"
echo "--------------------------------------------------------------------------------"

# Get image history and format output
# --no-trunc to see full command if needed, but we truncate for display
docker history --format "{{.ID}}\t{{.Size}}\t{{.CreatedBy}}" "$IMAGE" | while IFS=$'\t' read -r id size created_by; do
    # Truncate created_by for display
    truncated_cmd=$(echo "$created_by" | cut -c1-50)
    printf "%-15s %-15s %-50s\n" "$id" "$size" "$truncated_cmd"
done

echo "--------------------------------------------------------------------------------"
echo "Top 5 largest layers:"
docker history "$IMAGE" --format "{{.Size}}\t{{.CreatedBy}}" | sort -hr | head -n 5
