#!/bin/bash

# Script to monitor system entropy levels.
# High entropy is critical for cryptographic operations (SSL/TLS, key generation).
# Usage: ./check_system_entropy.sh [threshold]

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [threshold]"
    echo "  threshold: (optional) Minimum recommended entropy. Default: 1000"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

THRESHOLD=${1:-1000}

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: Threshold must be a positive integer."
    exit 1
fi

ENTROPY_FILE="/proc/sys/kernel/random/entropy_avail"
POOL_SIZE_FILE="/proc/sys/kernel/random/poolsize"

if [ ! -f "$ENTROPY_FILE" ]; then
    echo "Error: $ENTROPY_FILE not found. This script only works on Linux."
    exit 1
fi

CURRENT_ENTROPY=$(cat "$ENTROPY_FILE")
POOL_SIZE=$(cat "$POOL_SIZE_FILE" 2>/dev/null || echo "Unknown")

echo "--- System Entropy Status ---"
echo "Current available entropy: $CURRENT_ENTROPY"
echo "Entropy pool size:        $POOL_SIZE"
echo "Threshold set:            $THRESHOLD"

if [ "$CURRENT_ENTROPY" -lt "$THRESHOLD" ]; then
    echo -e "\nWARNING: Low entropy detected!"
    echo "Cryptographic operations might be slow or block."
    echo "Consider installing 'haveged' or 'rng-tools' if this is a recurring issue."
    exit 1
else
    echo -e "\nOK: System entropy is at a healthy level."
    exit 0
fi
