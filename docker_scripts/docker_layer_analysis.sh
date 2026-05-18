#!/bin/bash

# Script to analyze local Docker image layers and identify the largest contributors.
# Follows Bolt principles for performance/optimization awareness.
# Usage: ./docker_layer_analysis.sh <image_name>:<tag>

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <image_name>:<tag>"
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

if [ "$#" -ne 1 ]; then
    usage
fi

IMAGE=$1

echo "Analyzing layers for image: $IMAGE"
echo "---------------------------------------------------------"

# Use docker history to get layer sizes and commands
# We use --no-trunc to see the full command if needed, but for summary we keep it clean
docker history --format "table {{.ID}}\t{{.Size}}\t{{.CreatedBy}}" "$IMAGE" | \
    awk -F '\t' '
    BEGIN { print "LAYER_ID\tSIZE\tCOMMAND" }
    NR>1 {
        id=$1
        size_str=$2
        cmd=$3

        printf "%-15s %-10s %s\n", id, size_str, cmd
    }'

echo "---------------------------------------------------------"
echo "Top 5 largest layers:"
# We use a simple printf-based formatting if column is missing
docker history --format "{{.Size}}\t{{.ID}}\t{{.CreatedBy}}" "$IMAGE" | \
    sort -h -r | head -n 5 | awk -F '\t' '{printf "%-10s %-15s %s\n", $1, $2, $3}'

echo "---------------------------------------------------------"
echo "Layer analysis complete."
