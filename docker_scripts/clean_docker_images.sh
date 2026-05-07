#!/bin/bash
set -euo pipefail

images=$(docker images -q)

if [ -n "$images" ]; then
    echo "Removing all docker images..."
    docker rmi -f $images
else
    echo "No docker images found to remove."
fi
