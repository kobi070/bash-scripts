#!/bin/bash

# Script to inspect a running Docker container for common security misconfigurations.
# Checks for root user, privileged mode, and sensitive host mounts.
# Usage: ./docker_inspect_security.sh <container_name_or_id>
# Example: ./docker_inspect_security.sh my-web-app

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <container_name_or_id>"
    echo "  container_name_or_id: The name or ID of the running container."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed or not in PATH."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
    exit 1
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

CONTAINER=$1

# Verify container exists
if ! docker inspect "$CONTAINER" &> /dev/null; then
    echo "Error: Container '$CONTAINER' not found."
    exit 1
fi

echo "Security audit for container: $CONTAINER"
echo "--------------------------------------------------------------------------------"

INSPECT_DATA=$(docker inspect "$CONTAINER")

# 1. Check User
USER=$(echo "$INSPECT_DATA" | jq -r '.[0].Config.User')
if [ -z "$USER" ] || [ "$USER" == "0" ] || [ "$USER" == "root" ]; then
    echo "[!] WARNING: Container is running as ROOT (User: ${USER:-not set})."
else
    echo "[+] SUCCESS: Container is running as non-root user ($USER)."
fi

# 2. Check Privileged Mode
PRIVILEGED=$(echo "$INSPECT_DATA" | jq -r '.[0].HostConfig.Privileged')
if [ "$PRIVILEGED" == "true" ]; then
    echo "[!] DANGER: Container is running in PRIVILEGED mode."
else
    echo "[+] SUCCESS: Container is not privileged."
fi

# 3. Check for sensitive mounts
echo "Checking for sensitive host mounts..."
SENSITIVE_PATHS=("/" "/etc" "/var/run/docker.sock" "/usr/bin" "/bin" "/lib")
MOUNTS=$(echo "$INSPECT_DATA" | jq -r '.[0].Mounts[]? | .Source')

FOUND_SENSITIVE=0
for mount in $MOUNTS; do
    for sensitive in "${SENSITIVE_PATHS[@]}"; do
        if [ "$mount" == "$sensitive" ]; then
            echo "[!] WARNING: Sensitive host path mounted: $mount"
            FOUND_SENSITIVE=$((FOUND_SENSITIVE + 1))
        fi
    done
done

if [ "$FOUND_SENSITIVE" -eq 0 ]; then
    echo "[+] SUCCESS: No common sensitive host paths found in mounts."
fi

# 4. Check Network Mode
NET_MODE=$(echo "$INSPECT_DATA" | jq -r '.[0].HostConfig.NetworkMode')
if [ "$NET_MODE" == "host" ]; then
    echo "[!] WARNING: Container is using HOST network mode."
else
    echo "[+] SUCCESS: Container is using isolated network mode ($NET_MODE)."
fi

# 5. Check ReadOnlyRootfs
READ_ONLY=$(echo "$INSPECT_DATA" | jq -r '.[0].HostConfig.ReadonlyRootfs')
if [ "$READ_ONLY" == "true" ]; then
    echo "[+] SUCCESS: Root filesystem is READ-ONLY."
else
    echo "[!] INFO: Root filesystem is writable."
fi

echo "--------------------------------------------------------------------------------"
echo "Audit complete."
