#!/bin/bash
# check_url_content.sh - Waits for a URL to return 200 OK and verifies that the body contains a specific string.

set -euo pipefail

usage() {
    echo "Usage: $0 -u <url> -s <search_string> [-t <timeout>] [-i <interval>]"
    echo "  -u <url>            The URL to check"
    echo "  -s <search_string>  The string to look for in the response body"
    echo "  -t <timeout>        Timeout in seconds (defaults to 60)"
    echo "  -i <interval>       Interval between checks in seconds (defaults to 5)"
    echo "  -h, --help          Display this help message"
    exit 1
}

URL=""
SEARCH_STRING=""
TIMEOUT=60
INTERVAL=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            URL="$2"
            shift 2
            ;;
        -s|--search)
            SEARCH_STRING="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$URL" || -z "$SEARCH_STRING" ]]; then
    echo "Error: URL and Search String are required."
    usage
fi

# Security check: Ensure TIMEOUT and INTERVAL are numeric integers to prevent shell arithmetic injection
if [[ ! "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    echo "Error: TIMEOUT must be a positive numeric integer."
    exit 1
fi

if [[ ! "$INTERVAL" =~ ^[0-9]+$ ]]; then
    echo "Error: INTERVAL must be a positive numeric integer."
    exit 1
fi

# Verify dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed."
    exit 1
fi

echo "Waiting for $URL to be ready and contain '$SEARCH_STRING'..."
echo "Timeout: ${TIMEOUT}s, Interval: ${INTERVAL}s"

start_time=$SECONDS
end_time=$((start_time + TIMEOUT))

while [ $SECONDS -lt $end_time ]; do
    # Use curl to get the status code and the body
    # -s: silent
    # -L: follow redirects
    # -i: include headers (to get the status code)
    # We'll use -w to get the status code separately for easier checking

    response=$(curl -sL -w "%{http_code}" "$URL" || true)
    http_code="${response: -3}"
    body="${response%???}"

    if [[ "$http_code" == "200" ]]; then
        if echo "$body" | grep -q "$SEARCH_STRING"; then
            echo "Success: URL is reachable and contains the search string."
            exit 0
        else
            echo "URL is up (200 OK), but search string '$SEARCH_STRING' not found yet..."
        fi
    else
        echo "URL returned HTTP $http_code. Retrying..."
    fi

    sleep "$INTERVAL"
done

echo "Error: Timed out waiting for URL to be ready or contain the search string."
exit 1
