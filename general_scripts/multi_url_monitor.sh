#!/bin/bash

# Script to monitor multiple URLs and provide a health summary.
# Optionally sends a Slack notification if any URL fails.
# Usage: ./multi_url_monitor.sh <url1> [url2] ... OR ./multi_url_monitor.sh -f <file_with_urls>

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [options] <url1> [url2] ..."
    echo "Options:"
    echo "  -f <file>       Read URLs from a file (one per line)"
    echo "  -s              Send Slack notification on failure (requires SLACK_WEBHOOK_URL)"
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

URLS=()
SEND_SLACK=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f)
            if [[ -f "$2" ]]; then
                while IFS= read -r line; do
                    [[ -n "$line" && ! "$line" =~ ^# ]] && URLS+=("$line")
                done < "$2"
                shift 2
            else
                echo "Error: File $2 not found."
                exit 1
            fi
            ;;
        -s)
            SEND_SLACK=true
            shift
            ;;
        *)
            URLS+=("$1")
            shift
            ;;
    esac
done

if [ ${#URLS[@]} -eq 0 ]; then
    usage
fi

FAILED_URLS=()
RESULTS_STR=""

echo "Monitoring ${#URLS[@]} URLs..."
echo "---------------------------------------------------------"

# BOLT Optimization: Use curl --parallel to check all URLs concurrently if supported.
# This reduces the total execution time from O(N) to O(1) in terms of network round-trips.
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
write-out = \"$i\t%{http_code}\n\"
"
    done

    # Run curl in parallel and sort by index to preserve original order
    PARALLEL_RESULTS=$(echo "$CONFIG" | curl -K- --parallel 2>/dev/null | sort -n || true)

    if [ -n "$PARALLEL_RESULTS" ]; then
        while IFS=$'\t' read -r index status_code; do
            URL="${URLS[$index]}"
            if [[ "$status_code" -ge 200 && "$status_code" -lt 300 ]]; then
                MSG="[OK]   $status_code - $URL"
                echo "$MSG"
                RESULTS_STR+="$MSG\n"
            else
                MSG="[FAIL] $status_code - $URL"
                echo "$MSG"
                RESULTS_STR+="$MSG\n"
                FAILED_URLS+=("$URL")
            fi
        done <<< "$PARALLEL_RESULTS"
    else
        # Fallback if PARALLEL_RESULTS is empty
        for URL in "${URLS[@]}"; do
            MSG="[FAIL] 000 - $URL"
            echo "$MSG"
            RESULTS_STR+="$MSG\n"
            FAILED_URLS+=("$URL")
        done
    fi
else
    # Sequential execution for compatibility with older curl versions or single URL
    for URL in "${URLS[@]}"; do
        STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$URL" || echo "000")

        if [[ "$STATUS_CODE" -ge 200 && "$STATUS_CODE" -lt 300 ]]; then
            MSG="[OK]   $STATUS_CODE - $URL"
            echo "$MSG"
            RESULTS_STR+="$MSG\n"
        else
            MSG="[FAIL] $STATUS_CODE - $URL"
            echo "$MSG"
            RESULTS_STR+="$MSG\n"
            FAILED_URLS+=("$URL")
        fi
    done
fi

echo "---------------------------------------------------------"

if [ ${#FAILED_URLS[@]} -ne 0 ]; then
    echo "Warning: ${#FAILED_URLS[@]} URL(s) failed health check."

    if [ "$SEND_SLACK" = true ]; then
        if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
            echo "Error: SLACK_WEBHOOK_URL is not set. Cannot send notification."
        else
            # Prepare JSON payload using jq for safe character handling and compact output
            PAYLOAD=$(jq -n -c --arg text "*Multi-URL Monitor Alert*
Some services are down:
\`\`\`$RESULTS_STR\`\`\`" '{text: $text}')

            # Use curl config file via stdin to prevent leaking SLACK_WEBHOOK_URL in process lists (ps).
            # We must escape backslashes and double quotes for the curl config parser to prevent
            # configuration injection if a variable contains malicious characters.
            ESCAPED_WEBHOOK_URL=$(echo "$SLACK_WEBHOOK_URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
            ESCAPED_PAYLOAD=$(echo "$PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')
            printf "url = \"%s\"\ndata = \"%s\"" "$ESCAPED_WEBHOOK_URL" "$ESCAPED_PAYLOAD" | curl -s -X POST -H 'Content-type: application/json' -K- > /dev/null || echo "Error: Failed to send Slack notification."
            echo "Slack notification sent."
        fi
    fi
    exit 1
else
    echo "All URLs are healthy."
    exit 0
fi
