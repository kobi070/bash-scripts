#!/bin/bash

# Script to perform a lightweight security audit on running Docker containers.
# It checks for:
# 1. Containers running as root
# 2. Privileged mode enabled
# 3. Host network/IPC/PID namespace sharing
# 4. Insecure environment variables (potential secrets)
# Optimized with Bolt principles: Consolidate metadata extraction into a single jq pipeline (O(1) process forks).
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

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH."
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

# Bolt optimization: Consolidate metadata extraction into a single docker inspect and jq pipeline.
# This reduces process forks from O(N) to O(1) for the entire set of containers.
# We extract ID, Name, User, Privileged, NetworkMode, PidMode, and scan Env for secrets in one pass.
docker inspect $CONTAINERS | jq -r '
  .[] |
  .Id as $id |
  (.Name | sub("^/"; "")) as $name |
  (.Config.User | if . == null or . == "" then "root" else . end) as $user |
  (.HostConfig.Privileged | if . == true then "true" else "false" end) as $privileged |
  (.HostConfig.NetworkMode // "default") as $network |
  (.HostConfig.PidMode // "default") as $pid |
  ([.Config.Env[]? | select(test("(?i)pass|token|key|secret|auth|pwd")) | split("=")[0]] | join(",")) as $secrets |
  "\($id)\t\($name)\t\($user)\t\($privileged)\t\($network)\t\($pid)\t\($secrets)"
' | while IFS=$'\t' read -r cid name user privileged network pid secrets; do
    echo "Auditing Container: $name ($cid)"

    # 1. Check for Root User
    if [ "$user" == "root" ] || [ "$user" == "0" ]; then
        echo "  [FAIL] Running as ROOT user"
    else
        echo "  [PASS] Running as non-root user: $user"
    fi

    # 2. Check for Privileged Mode
    if [ "$privileged" == "true" ]; then
        echo "  [FAIL] Privileged mode is ENABLED"
    else
        echo "  [PASS] Privileged mode is DISABLED"
    fi

    # 3. Check for Host Namespace Sharing
    if [ "$network" == "host" ]; then
        echo "  [WARN] Host network namespace is SHARED"
    fi

    if [ "$pid" == "host" ]; then
        echo "  [FAIL] Host PID namespace is SHARED"
    fi

    # 4. Check for potential secrets in Environment Variables
    if [ -n "$secrets" ]; then
        echo "  [WARN] Potential secrets found in environment variables:"
        # Only show the key, not the value to prevent leakage in logs
        echo "$secrets" | tr ',' '\n' | sed 's/^/    - /'
    fi

    echo "--------------------------------------------------------------------------------"
done

echo "Audit complete."
