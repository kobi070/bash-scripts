#!/bin/bash

# Script to send a message to a Slack channel using a Webhook URL.
# Useful for CI/CD notifications about pipeline status.
# Usage: ./send_slack_notification.sh <webhook_url> <message> [channel] [username]
# Example: ./send_slack_notification.sh "https://hooks.slack.com/services/..." "Build Successful" "#ci-builds" "CI Bot"
# Note: Recommends using SLACK_WEBHOOK_URL environment variable to avoid secret exposure.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <webhook_url> <message> [channel] [username]"
    echo "  webhook_url: The Slack Incoming Webhook URL. (Prefer SLACK_WEBHOOK_URL env var)"
    echo "  message: The message to send"
    echo "  channel: (optional) The channel to post to"
    echo "  username: (optional) The bot username"
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

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ] && [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
    usage
fi

# Credential selection: Environment variable prioritized over argument
WEBHOOK_URL=${SLACK_WEBHOOK_URL:-${1:-}}
MESSAGE=${2:-${SLACK_MESSAGE:-}}
CHANNEL=${3:-}
USERNAME=${4:-"DevOps Bot"}

if [ -z "$WEBHOOK_URL" ]; then
    echo "Error: Slack Webhook URL must be provided via SLACK_WEBHOOK_URL environment variable or as the 1st argument."
    exit 1
fi

if [ -z "$MESSAGE" ]; then
    echo "Error: Message must be provided via SLACK_MESSAGE environment variable or as the 2nd argument."
    exit 1
fi

if [ -z "${SLACK_WEBHOOK_URL:-}" ] && [ -n "${1:-}" ]; then
    echo "WARNING: Passing secrets as command-line arguments is insecure."
    echo "Consider using SLACK_WEBHOOK_URL environment variable."
fi

echo "Sending Slack notification..."

# Prepare JSON payload (compacted)
PAYLOAD=$(jq -n -c \
    --arg text "$MESSAGE" \
    --arg channel "$CHANNEL" \
    --arg username "$USERNAME" \
    '{text: $text, channel: $channel, username: $username}' | jq -c 'with_entries(select(.value != ""))')

# Send POST request to Slack
# Use curl config file via stdin to prevent leaking WEBHOOK_URL in process lists (ps)
# We must escape backslashes and double quotes for the curl config parser
ESCAPED_WEBHOOK_URL=$(echo "$WEBHOOK_URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
ESCAPED_PAYLOAD=$(echo "$PAYLOAD" | sed 's/\\/\\\\/g; s/"/\\"/g')
RESPONSE=$(printf "url = \"%s\"\ndata = \"%s\"" "$ESCAPED_WEBHOOK_URL" "$ESCAPED_PAYLOAD" | curl -s -X POST -H 'Content-type: application/json' -K- || echo "connection_error")

if [ "$RESPONSE" == "ok" ]; then
    echo "Success: Slack notification sent."
else
    echo "Error: Failed to send Slack notification. Response: $RESPONSE"
    exit 1
fi
