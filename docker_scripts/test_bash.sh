#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status
EMPTY_STRING=""

if [ -z "$EMPTY_STRING" ]; then
    echo "The string is empty."
else
    echo "The string is not empty."
fi

# Check if login is required
if [ -z "$(docker info | grep 'Username: ' | awk '{print $2}')" ]; then
    echo "You are not logged in to Docker Hub."
fi
