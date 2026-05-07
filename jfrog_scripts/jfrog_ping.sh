#!/bin/bash
set -euo pipefail

# This script pings a JFrog Artifactory instance to check its health.

usage() {
    echo "Usage: $0 <artifactory_url>"
    echo "Example: $0 https://myartifactory.jfrog.io/artifactory"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

url=$1

echo "Pinging JFrog Artifactory at $url..."
if curl -s -f "$url/api/system/ping" > /dev/null; then
    echo "✅ Artifactory is UP and reachable."
else
    echo "❌ Error: Could not reach Artifactory at $url."
    exit 1
fi
