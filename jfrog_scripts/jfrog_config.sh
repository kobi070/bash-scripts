#!/bin/bash

# Script to configure the JFrog CLI with server details.
# Useful for initializing JFrog CLI in CI/CD environments.
# Usage: ./jfrog_config.sh <server_id> <url> <user> <password_or_token>
# Example: ./jfrog_config.sh my-artifactory https://artifactory.example.com admin AKCp8hj...

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <server_id> <url> <user> <password_or_token>"
    echo "  server_id: A unique identifier for this server configuration"
    echo "  url: The JFrog Artifactory URL"
    echo "  user: The username"
    echo "  password_or_token: The password or API key/token"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI (jf or jfrog) is not installed or not in PATH."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

# Input validation
if [ "$#" -ne 4 ]; then
    usage
fi

SERVER_ID=$1
URL=$2
USER=$3
PASSWORD=$4

echo "Configuring JFrog CLI for server: $SERVER_ID..."

# Configure the server
# Use --overwrite to ensure we update if it already exists
$JF_BIN c add "$SERVER_ID" \
    --url="$URL" \
    --user="$USER" \
    --password="$PASSWORD" \
    --interactive=false \
    --overwrite

echo "Success: JFrog CLI configured for $SERVER_ID."

# Set as default
$JF_BIN c use "$SERVER_ID"
echo "Server $SERVER_ID set as default."
