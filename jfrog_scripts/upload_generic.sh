#!/bin/bash
set -euo pipefail

# This script uploads a file to JFrog Artifactory using the generic upload API.
# Usage: ./upload_generic.sh <local_file_path> <target_path_in_repo>

if [ $# -ne 2 ]; then
  echo "Usage: $0 <local_file_path> <target_path_in_repo>"
  exit 1
fi

# Validate environment variables
for var in JFROG_API_KEY JFROG_URL JFROG_REPO; do
  # Security Pattern: Prevent command injection via indirect expansion by validating the variable name
  if [[ ! "$var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Error: $var is not a valid environment variable name."
    exit 1
  fi
  if [ -z "${!var:-}" ]; then
    echo "Error: Environment variable $var is not set."
    exit 1
  fi
done

LOCAL_FILE="$1"
TARGET_PATH="$2"

if [ ! -f "$LOCAL_FILE" ]; then
  echo "Error: Local file '$LOCAL_FILE' not found."
  exit 1
fi

# Use curl config file via stdin to prevent leaking JFROG_API_KEY in process lists (ps)
# Security Pattern: Escape backslashes and double quotes for curl config parser
ESCAPED_KEY=$(echo "$JFROG_API_KEY" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf "header = \"X-JFrog-Art-Api: %s\"\n" "$ESCAPED_KEY" | curl -sS -K- \
  -H "Content-Type: application/octet-stream" \
  -T "$LOCAL_FILE" \
  "$JFROG_URL/$JFROG_REPO/$TARGET_PATH"

echo "File uploaded successfully to $JFROG_URL/$JFROG_REPO/$TARGET_PATH"
