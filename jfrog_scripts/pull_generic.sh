#!/bin/bash
set -e

# This script downloads a file from JFrog Artifactory.
# Usage: ./pull_generic.sh <source_file_path_in_repo> <local_output_filename>

if [ $# -ne 2 ]; then
  echo "Usage: $0 <source_file_path_in_repo> <local_output_filename>"
  exit 1
fi

SOURCE_PATH="$1"
OUTPUT_FILENAME="$2"

curl -v -H "X-JFrog-Art-Api:$JFROG_API_KEY" \
     -L -o "$OUTPUT_FILENAME" \
     "$JFROG_URL/$JFROG_REPO/$SOURCE_PATH"

echo "File pulled successfully from $JFROG_URL/$JFROG_REPO/$SOURCE_PATH"
