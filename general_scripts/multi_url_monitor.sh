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
RESULTS=""

echo "Monitoring ${#URLS[@]} URLs..."
echo "---------------------------------------------------------"

for URL in "${URLS[@]}"; do
    STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$URL" || echo "000")

    if [[ "$STATUS_CODE" -ge 200 && "$STATUS_CODE" -lt 300 ]]; then
        MSG="[OK]   $STATUS_CODE - $URL"
        echo "$MSG"
        RESULTS+="$MSG\n"
    else
        MSG="[FAIL] $STATUS_CODE - $URL"
        echo "$MSG"
        RESULTS+="$MSG\n"
        FAILED_URLS+=("$URL")
    fi
done

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
\`\`\`$RESULTS\`\`\`" '{text: $text}')

            # Use curl config file via stdin to prevent leaking SLACK_WEBHOOK_URL in process lists (ps)
            # We must escape backslashes and double quotes for the curl config parser
            ESCAPED_PAYLOAD=$(echo "$PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')
            printf "url = \"%s\"\ndata = \"%s\"" "$SLACK_WEBHOOK_URL" "$ESCAPED_PAYLOAD" | curl -s -X POST -H 'Content-type: application/json' -K- > /dev/null || echo "Error: Failed to send Slack notification."
            echo "Slack notification sent."
        fi
    fi
    exit 1
else
    echo "All URLs are healthy."
    exit 0
fi
