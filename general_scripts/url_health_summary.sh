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

# Use curl --parallel to check all URLs concurrently.
# This reduces the total execution time from O(N) to O(1) in terms of latency bottlenecks
# and reduces process forks from O(N) to O(1).
for url in "$@"; do
    printf "url = \"%s\"\n" "$url"
done | curl -s --parallel -o /dev/null -K- -w "%{url_effective}\t%{http_code}\t%{time_total}\n" | while IFS=$'\t' read -r url code latency; do
    if [ "$code" == "000" ]; then
        printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
    else
        printf "%-40s %-15s %-15s\n" "$url" "$code" "$latency"
    fi
done
