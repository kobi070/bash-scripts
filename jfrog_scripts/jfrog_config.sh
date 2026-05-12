#!/bin/bash

# Script to configure the JFrog CLI with server details.
# Useful for initializing JFrog CLI in CI/CD environments.
# Usage: ./jfrog_config.sh <server_id> <url> <user> [password_or_token]
# Example: ./jfrog_config.sh my-artifactory https://artifactory.example.com admin AKCp8hj...
# Note: Recommends using JFROG_PASSWORD, JFROG_API_KEY, or JFROG_TOKEN environment variables
# to avoid secret exposure in process lists and shell history.

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <server_id> <url> <user> [password_or_token]"
    echo "  server_id: A unique identifier for this server configuration"
    echo "  url: The JFrog Artifactory URL"
    echo "  user: The username"
    echo "  password_or_token: (Optional) The password or API key/token. "
    echo "                     Better to use JFROG_PASSWORD, JFROG_API_KEY, or JFROG_TOKEN env var."
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
if [ "$#" -lt 3 ]; then
    usage
fi

SERVER_ID=$1
URL=$2
USER=$3

# Credential selection: Environment variable prioritized over argument
PASSWORD=${JFROG_PASSWORD:-${JFROG_API_KEY:-${JFROG_TOKEN:-${4:-}}}}

if [ -z "$PASSWORD" ]; then
    echo "Error: Password, API key, or token must be provided via environment variable"
    echo "(JFROG_PASSWORD, JFROG_API_KEY, or JFROG_TOKEN) or as the 4th argument."
    exit 1
fi

if [ -z "${JFROG_PASSWORD:-}${JFROG_API_KEY:-}${JFROG_TOKEN:-}" ] && [ -n "${4:-}" ]; then
    echo "WARNING: Passing secrets as command-line arguments is insecure."
    echo "Consider using JFROG_PASSWORD, JFROG_API_KEY, or JFROG_TOKEN environment variables."
fi

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
