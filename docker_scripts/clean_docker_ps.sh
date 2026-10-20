#!/bin/bash
set -euo pipefail

# Remove all Docker containers (force).
containers=$(docker ps -aq)
if [ -z "$containers" ]; then
  echo "No Docker containers to remove."
  exit 0
fi
echo "$containers" | xargs docker rm -f
