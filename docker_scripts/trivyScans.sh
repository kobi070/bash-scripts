#!/bin/bash
# Script to run Trivy scans (FS, Image, Docker-compose, Running container)
# Usage: ./trivyScans.sh <directory> <MODE: lmh|critical> <OUTPUT_FORMAT: table|json|html|sarif> <IMAGE> <IMAGE_TAG>
# Example: ./trivyScans.sh ./scans lmh json nginx latest
# Version: 1.0.3
set -euo pipefail

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <directory> <MODE: lmh|critical> <OUTPUT_FORMAT: table|json|html|sarif> <IMAGE> <IMAGE_TAG>"
    exit 1
fi

DIRECTORY=$1
MODE=$2
OUTPUT_FORMAT=$3
IMAGE=$4
IMAGE_TAG=$5

if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

if [[ "$MODE" != "lmh" && "$MODE" != "critical" ]]; then
    echo "Error: Invalid mode '$MODE'. Use 'lmh' or 'critical'."
    exit 1
fi

if ! docker image inspect "$IMAGE:$IMAGE_TAG" > /dev/null 2>&1; then
    echo "Error: Docker image '$IMAGE:$IMAGE_TAG' does not exist."
    exit 1
fi

# Set severity
if [ "$MODE" == "lmh" ]; then
    SEVERITY="LOW,MEDIUM,HIGH"
    OUTPUT_FILE="trivy-low-med-high"
else
    SEVERITY="CRITICAL"
    OUTPUT_FILE="trivy-crit"
fi

SANITIZED_IMAGE=$(echo "$IMAGE" | tr '/:' '_')

# Map output format
if [ "$OUTPUT_FORMAT" == "table" ]; then
    TRIVY_FORMAT="table"
    OUTPUT_FILE_EXT="txt"
elif [ "$OUTPUT_FORMAT" == "html" ]; then
    TRIVY_FORMAT="html"
    OUTPUT_FILE_EXT="html"
else
    TRIVY_FORMAT="$OUTPUT_FORMAT"
    OUTPUT_FILE_EXT="$OUTPUT_FORMAT"
fi

echo "Running Trivy scans..."
echo " Directory: $DIRECTORY"
echo " Image: $IMAGE:$IMAGE_TAG"
echo " Severity: $SEVERITY"
echo " Output format: $OUTPUT_FORMAT"

# FS scan (vuln + misconfig)
docker run --rm \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  -v "$HOME/Library/Caches:/root/.cache/" \
  artifactory.rafael.co.il:6003/aquasec/trivy/trivy-offline fs \
  --scanners vuln,misconf \
  --severity "$SEVERITY" \
  --format "$TRIVY_FORMAT" \
  -o "$DIRECTORY/fs-$OUTPUT_FILE.$OUTPUT_FILE_EXT" "$DIRECTORY"

# Image scan (vuln + misconfig)
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$HOME/Library/Caches:/root/.cache/" \
  artifactory.rafael.co.il:6003/aquasec/trivy/trivy-offline image \
  --scanners vuln,misconf \
  --severity "$SEVERITY" \
  --format "$TRIVY_FORMAT" \
  -o "$DIRECTORY/${SANITIZED_IMAGE}-$OUTPUT_FILE.$OUTPUT_FILE_EXT" "$IMAGE:$IMAGE_TAG"

# Docker-compose scan (misconfig only)
if comp_file=$(find "$DIRECTORY" -maxdepth 1 -name "docker-compose*.yml" | head -n 1); then
  echo "Found docker-compose file: $comp_file"
  docker run --rm \
    -v "$PWD:$PWD" \
    -w "$PWD" \
    -v "$HOME/Library/Caches:/root/.cache/" \
    artifactory.rafael.co.il:6003/aquasec/trivy/trivy-offline config \
    --format "$TRIVY_FORMAT" \
    -o "$DIRECTORY/compose-$OUTPUT_FILE.$OUTPUT_FILE_EXT" "$comp_file"
else
  echo "No docker-compose.yml found in $DIRECTORY, skipping compose scan."
fi

# Running container scan (vuln + misconfig)
CONTAINER_ID=$(docker ps --filter "ancestor=$IMAGE:$IMAGE_TAG" --format "{{.ID}}" | head -n 1 || true)
if [ -n "$CONTAINER_ID" ]; then
  echo "Found running container ($CONTAINER_ID) for image $IMAGE:$IMAGE_TAG"
  
  TMP_ROOTFS=$(mktemp -d)
  echo "Exporting container filesystem to $TMP_ROOTFS..."
  docker export "$CONTAINER_ID" | tar -C "$TMP_ROOTFS" -xf -

  HOST_DIR=$(realpath "$DIRECTORY")   # Use absolute path for mounting
  
  docker run --rm \
    -v "$TMP_ROOTFS:$TMP_ROOTFS:ro" \
    -v "$HOST_DIR:$HOST_DIR" \
    -v "$HOME/Library/Caches:/root/.cache/" \
    artifactory.rafael.co.il:6003/aquasec/trivy/trivy-offline rootfs \
    --scanners vuln,misconf \
    --severity "$SEVERITY" \
    --format "$TRIVY_FORMAT" \
    -o "$HOST_DIR/container-$OUTPUT_FILE.$OUTPUT_FILE_EXT" "$TMP_ROOTFS"
  
  echo "Cleaning up temporary rootfs..."
  rm -rf "$TMP_ROOTFS"
else
  echo "No running container found for $IMAGE:$IMAGE_TAG, skipping container scan."
fi

echo "All scans completed."
echo "Results saved in $DIRECTORY"
