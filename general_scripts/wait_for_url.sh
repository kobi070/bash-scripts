#!/bin/bash

# Script to wait for a URL to return a 200 OK status code.
# Useful for CI/CD pipelines to wait for a service to be ready.
# Usage: ./wait_for_url.sh <url> [timeout] [interval]
# Example: ./wait_for_url.sh http://localhost:8080/health 60 5

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <url> [timeout] [interval]"
    echo "  url: The URL to check"
    echo "  timeout: (optional) Maximum time to wait in seconds. Default: 60"
    echo "  interval: (optional) Time between checks in seconds. Default: 5"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

URL=$1
TIMEOUT=${2:-60}
INTERVAL=${3:-5}

# Security check: Ensure TIMEOUT and INTERVAL are numeric integers to prevent shell arithmetic injection
if [[ ! "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    echo "Error: TIMEOUT must be a positive numeric integer."
    exit 1
fi

if [[ ! "$INTERVAL" =~ ^[0-9]+$ ]]; then
    echo "Error: INTERVAL must be a positive numeric integer."
    exit 1
fi

echo "Waiting for URL $URL to return 200 OK (timeout: ${TIMEOUT}s, interval: ${INTERVAL}s)..."

# Optimized: Use Bash builtin $SECONDS to avoid repetitive 'date' process forks
SECONDS=0

while [ "$SECONDS" -lt "$TIMEOUT" ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || true)

    if [ "$HTTP_CODE" == "200" ]; then
        echo "Success: URL $URL is reachable and returned 200 OK."
        exit 0
    fi

    echo "Current status code: $HTTP_CODE. Retrying in ${INTERVAL}s..."
    sleep "$INTERVAL"
done

echo "Error: Timed out waiting for URL $URL after ${TIMEOUT}s."
exit 1
