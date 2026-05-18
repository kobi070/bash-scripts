#!/bin/bash

# Script to report status codes and latency for a list of URLs.
# Useful for monitoring endpoint health across multiple services.
# Usage: ./url_health_summary.sh <url1> [url2] ... [urlN]
# Example: ./url_health_summary.sh https://google.com https://github.com

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <url1> [url2] ... [urlN]"
    echo "  url: One or more URLs to check."
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

echo "Checking health for provided URLs..."
echo "--------------------------------------------------------------------------------"
printf "%-40s %-15s %-15s\n" "URL" "STATUS CODE" "LATENCY (s)"
echo "--------------------------------------------------------------------------------"

for url in "$@"; do
    # Use curl to get status code and latency
    # -o /dev/null: don't output the body
    # -s: silent mode
    # -w: custom output format
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}\t%{time_total}" "$url" || echo "ERROR")

    if [ "$RESPONSE" == "ERROR" ]; then
        printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
    else
        STATUS_CODE=$(echo "$RESPONSE" | cut -f1)
        LATENCY=$(echo "$RESPONSE" | cut -f2)
        printf "%-40s %-15s %-15s\n" "$url" "$STATUS_CODE" "$LATENCY"
    fi
done
