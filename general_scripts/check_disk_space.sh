#!/bin/bash

# Script to check disk space and warn if usage exceeds a threshold.
# Useful for monitoring disk health in CI/CD runners or servers.
# Usage: ./check_disk_space.sh [threshold_percent] [mount_point]
# Example: ./check_disk_space.sh 80 /

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [threshold_percent] [mount_point]"
    echo "  threshold_percent: (optional) Warn if usage is above this percentage. Default: 90"
    echo "  mount_point: (optional) The mount point to check. Default: /"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

THRESHOLD=${1:-90}
MOUNT_POINT=${2:-/}

echo "Checking disk usage for $MOUNT_POINT (threshold: ${THRESHOLD}%)..."

# Get usage percentage
# df -Ph ensures POSIX-compliant output format (single line per filesystem)
# awk NR==2 picks the second line (data), removes '%' from the 5th column, and prints it
# This reduces 4 process forks (df|tail|awk|sed) to 2 (df|awk)
USAGE=$(df -Ph "$MOUNT_POINT" | awk 'NR==2 {sub(/%/, "", $5); print $5}')

echo "Current usage: ${USAGE}%"

if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "WARNING: Disk usage on $MOUNT_POINT is at ${USAGE}%, exceeding the threshold of ${THRESHOLD}%!"
    exit 1
else
    echo "OK: Disk usage is within limits."
    exit 0
fi
