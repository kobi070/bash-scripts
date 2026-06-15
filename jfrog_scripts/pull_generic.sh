#!/bin/bash
set -euo pipefail

# This script downloads a file from JFrog Artifactory.
# Usage: ./pull_generic.sh <source_file_path_in_repo> <local_output_filename>

if [ $# -ne 2 ]; then
  echo "Usage: $0 <source_file_path_in_repo> <local_output_filename>"
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

SOURCE_PATH="$1"
OUTPUT_FILENAME="$2"

# Use curl config file via stdin to prevent leaking JFROG_API_KEY in process lists (ps)
# Security Pattern: Escape backslashes and double quotes for curl config parser
ESCAPED_KEY=$(echo "$JFROG_API_KEY" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf "header = \"X-JFrog-Art-Api: %s\"\n" "$ESCAPED_KEY" | curl -sS -K- \
     -L -o "$OUTPUT_FILENAME" \
     "$JFROG_URL/$JFROG_REPO/$SOURCE_PATH"

echo "File pulled successfully from $JFROG_URL/$JFROG_REPO/$SOURCE_PATH"
