#!/bin/bash

# Script to find files larger than a specified size in a directory.
# Useful for cleaning up workspace or identifying unexpectedly large artifacts.
# Usage: ./find_large_files.sh <directory> <min_size_mb>
# Example: ./find_large_files.sh /home/ubuntu/downloads 100

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <directory> <min_size_mb>"
    echo "  directory: The directory to search in"
    echo "  min_size_mb: Minimum file size in Megabytes (MB)"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Input validation
if [ "$#" -ne 2 ]; then
    usage
fi

SEARCH_DIR=$1
MIN_SIZE=$2

# Security check: Ensure input is a numeric integer to prevent shell arithmetic injection
if [[ ! "$MIN_SIZE" =~ ^[0-9]+$ ]]; then
    echo "Error: MIN_SIZE must be a positive numeric integer."
    exit 1
fi

if [ ! -d "$SEARCH_DIR" ]; then
    echo "Error: Directory $SEARCH_DIR does not exist."
    exit 1
fi

echo "Searching for files larger than ${MIN_SIZE}MB in $SEARCH_DIR..."

# Use find to locate large files
# Using -size +${MIN_SIZE}M requires an integer.
# We'll use kilobyte for more precision if the user wants.
MIN_SIZE_KB=$(echo "$MIN_SIZE * 1024 / 1" | bc 2>/dev/null || echo "$((MIN_SIZE * 1024))")
find "$SEARCH_DIR" -type f -size "+${MIN_SIZE_KB}k" -exec ls -lh {} + | awk '{print $5, $9}' || echo "No files larger than ${MIN_SIZE}MB found."
