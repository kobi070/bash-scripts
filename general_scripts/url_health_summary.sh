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

URLS=("$@")

echo "Checking health for provided URLs..."
echo "--------------------------------------------------------------------------------"
printf "%-40s %-15s %-15s\n" "URL" "STATUS CODE" "LATENCY (s)"
echo "--------------------------------------------------------------------------------"

# BOLT Optimization: Use curl --parallel to check all URLs concurrently if supported.
# This reduces the total execution time from O(N) to O(1) in terms of network round-trips.
# We check for --parallel support (curl >= 7.66.0) and fall back to sequential if missing.
PARALLEL_SUPPORTED=false
if curl --help all 2>/dev/null | grep -q -- "--parallel"; then
    PARALLEL_SUPPORTED=true
fi

if [ "$PARALLEL_SUPPORTED" = "true" ] && [ "${#URLS[@]}" -gt 1 ]; then
    CONFIG=""
    for i in "${!URLS[@]}"; do
        URL="${URLS[$i]}"
        # Escape double quotes and backslashes for curl config to prevent injection
        ESCAPED_URL=$(echo "$URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
        if [ "$i" -gt 0 ]; then
            CONFIG+="next
"
        fi
        CONFIG+="url = \"$ESCAPED_URL\"
output = /dev/null
silent
max-time = 10
write-out = \"$i\t%{http_code}\t%{time_total}\n\"
"
    done

    # Run curl in parallel and sort by index to preserve original order
    # We use || true because curl might exit with non-zero if some URLs fail,
    # but we want to process the results for all URLs that were checked.
    RESULTS=$(echo "$CONFIG" | curl -K- --parallel 2>/dev/null | sort -n || true)

    if [ -n "$RESULTS" ]; then
        while IFS=$'\t' read -r index status_code latency; do
            url="${URLS[$index]}"
            if [[ "$status_code" == "000" ]]; then
                printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
            else
                printf "%-40s %-15s %-15s\n" "$url" "$status_code" "$latency"
            fi
        done <<< "$RESULTS"
    else
        # Fallback if RESULTS is empty
        for url in "${URLS[@]}"; do
            printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
        done
    fi
else
    # Sequential execution for compatibility with older curl versions or single URL
    for url in "${URLS[@]}"; do
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}\t%{time_total}" --max-time 10 "$url" || echo "ERROR")

        if [ "$RESPONSE" == "ERROR" ]; then
            printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
        else
            STATUS_CODE=$(echo "$RESPONSE" | cut -f1)
            LATENCY=$(echo "$RESPONSE" | cut -f2)
            if [ "$STATUS_CODE" == "000" ]; then
                printf "%-40s %-15s %-15s\n" "$url" "FAILED" "N/A"
            else
                printf "%-40s %-15s %-15s\n" "$url" "$STATUS_CODE" "$LATENCY"
            fi
        fi
    done
fi
