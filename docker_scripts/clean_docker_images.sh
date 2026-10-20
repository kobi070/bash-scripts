#!/bin/bash
set -euo pipefail

# Remove all Docker images (force).
images=$(docker images -q)
if [ -z "$images" ]; then
  echo "No Docker images to remove."
  exit 0
fi
echo "$images" | xargs docker rmi -f
