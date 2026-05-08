#!/bin/bash

# Script to send a message to a Slack channel using a Webhook URL.
# Useful for CI/CD notifications about pipeline status.
# Usage: ./send_slack_notification.sh <webhook_url> <message> [channel] [username]
# Example: ./send_slack_notification.sh "https://hooks.slack.com/services/..." "Build Successful" "#ci-builds" "CI Bot"

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <webhook_url> <message> [channel] [username]"
    echo "  webhook_url: The Slack Incoming Webhook URL"
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
if [ "$#" -lt 2 ]; then
    usage
fi

WEBHOOK_URL=$1
MESSAGE=$2
CHANNEL=${3:-""}
USERNAME=${4:-"DevOps Bot"}

echo "Sending Slack notification..."

# Prepare JSON payload
PAYLOAD=$(jq -n \
    --arg text "$MESSAGE" \
    --arg channel "$CHANNEL" \
    --arg username "$USERNAME" \
    '{text: $text, channel: $channel, username: $username}' | jq 'with_entries(select(.value != ""))')

# Send POST request to Slack
RESPONSE=$(curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$WEBHOOK_URL")

if [ "$RESPONSE" == "ok" ]; then
    echo "Success: Slack notification sent."
else
    echo "Error: Failed to send Slack notification. Response: $RESPONSE"
    exit 1
fi
