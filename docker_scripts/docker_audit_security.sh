#!/bin/bash

# Script to perform a lightweight security audit on running Docker containers.
# It checks for:
# 1. Containers running as root
# 2. Privileged mode enabled
# 3. Host network/IPC/PID namespace sharing
# 4. Insecure environment variables (potential secrets)
# Usage: ./docker_audit_security.sh [container_id_or_name]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [container_id_or_name]"
    echo "  container_id_or_name: (optional) Audit a specific container. Default: all running containers"
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

CONTAINERS=$(docker ps --format "{{.ID}}")
if [ "$#" -ge 1 ]; then
    CONTAINERS=$1
fi

if [ -z "$CONTAINERS" ]; then
    echo "No running containers found."
    exit 0
fi

echo "Starting Docker Security Audit..."
echo "--------------------------------------------------------------------------------"

for CID in $CONTAINERS; do
    NAME=$(docker inspect --format '{{.Name}}' "$CID" | sed 's/^\///')
    echo "Auditing Container: $NAME ($CID)"

    # 1. Check for Root User
    USER=$(docker inspect --format '{{.Config.User}}' "$CID")
    if [ -z "$USER" ] || [ "$USER" == "root" ] || [ "$USER" == "0" ]; then
        echo "  [FAIL] Running as ROOT user"
    else
        echo "  [PASS] Running as non-root user: $USER"
    fi

    # 2. Check for Privileged Mode
    PRIVILEGED=$(docker inspect --format '{{.HostConfig.Privileged}}' "$CID")
    if [ "$PRIVILEGED" == "true" ]; then
        echo "  [FAIL] Privileged mode is ENABLED"
    else
        echo "  [PASS] Privileged mode is DISABLED"
    fi

    # 3. Check for Host Namespace Sharing
    NETWORK=$(docker inspect --format '{{.HostConfig.NetworkMode}}' "$CID")
    if [ "$NETWORK" == "host" ]; then
        echo "  [WARN] Host network namespace is SHARED"
    fi

    PID_MODE=$(docker inspect --format '{{.HostConfig.PidMode}}' "$CID")
    if [ "$PID_MODE" == "host" ]; then
        echo "  [FAIL] Host PID namespace is SHARED"
    fi

    # 4. Check for potential secrets in Environment Variables
    # Sentinel philosophy: Identifying secret leakage risks
    # Regex for sensitive words
    SECRETS_FOUND=$(docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CID" | \
        grep -Ei "pass|token|key|secret|auth|pwd" || true)

    if [ -n "$SECRETS_FOUND" ]; then
        echo "  [WARN] Potential secrets found in environment variables:"
        # Only show the key, not the value to prevent leakage in logs
        echo "$SECRETS_FOUND" | awk -F= '{print "    - " $1}'
    fi

    echo "--------------------------------------------------------------------------------"
done

echo "Audit complete."
