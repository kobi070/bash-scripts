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

# Bolt optimization: Consolidate curl calls into a single parallel invocation.
# This reduces process forks from O(N) to O(1) and enables concurrent health checks.
# We use curl -K- to read configurations from stdin and --parallel for concurrency.
{
    for url in "$@"; do
        printf "url = \"%s\"\noutput = /dev/null\nsilent\n" "$url"
    done
} | curl -K- --parallel -w "%{url_effective}\t%{http_code}\t%{time_total}\n" 2>/dev/null | while IFS=$'\t' read -r url status latency; do
    # curl returns 000 if the request failed (e.g., DNS error, connection refused)
    if [ "$status" == "000" ]; then
        printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
    else
        printf "%-40s %-15s %-15s\n" "$url" "$status" "$latency"
    fi
done

echo "--------------------------------------------------------------------------------"
