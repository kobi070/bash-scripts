#!/bin/bash
set -e

# This script uploads a file to JFrog Artifactory using the generic upload API.
# Usage: ./upload_generic.sh <local_file_path> <target_path_in_repo>

if [ $# -ne 2 ]; then
  echo "Usage: $0 <local_file_path> <target_path_in_repo>"
  exit 1
fi

LOCAL_FILE="$1"
TARGET_PATH="$2"

curl -v \
  -H "X-JFrog-Art-Api: $JFROG_API_KEY" \
  -H "Content-Type: application/octet-stream" \
  -T "$LOCAL_FILE" \
  "$JFROG_URL/$JFROG_REPO/$TARGET_PATH"

echo "File uploaded successfully to $JFROG_URL/$JFROG_REPO/$TARGET_PATH"
