#!/bin/bash
set -e

# This script uploads a file to JFrog Artifactory using the generic upload API.
# Usage: ./upload_generic.sh <file_path> <target_path>
curl -v -H X-JFrog-Art-Api:$JFROG_API_KEY \
     -H "Content-Type: application/octet-stream" \
     -T "$1" \
     "$JFROG_URL/api/storage/$JFROG_REPO/"