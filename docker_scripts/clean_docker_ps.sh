#!/bin/bash
set -euo pipefail

containers=$(docker ps -aq)

if [ -n "$containers" ]; then
    echo "Removing all docker containers..."
    docker rm -f $containers
else
    echo "No docker containers found to remove."
fi
