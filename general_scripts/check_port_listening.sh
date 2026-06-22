#!/bin/bash

# Script to check if a list of ports is currently listening on localhost.
# Useful for verifying service readiness or troubleshooting connection issues.
# Usage: ./check_port_listening.sh <port1> [port2] ...
# Example: ./check_port_listening.sh 80 443 8080

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <port1> [port2] ..."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

if [ "$#" -lt 1 ]; then
    usage
fi

# Determine the best tool to use
if command -v ss &> /dev/null; then
    CHECK_CMD="ss -lntu"
elif command -v netstat &> /dev/null; then
    CHECK_CMD="netstat -lntu"
else
    echo "Error: Neither 'ss' nor 'netstat' is installed."
    exit 1
fi

echo "Checking listening ports..."
echo "---------------------------------------------------------"

ALL_PASSED=true

# Bolt optimization: Consolidate the ss/netstat call to run once before the loop.
# This reduces process forks from O(N) to O(1).
# We store the output in a variable and use Bash built-in regex for matching.
LISTENING_DATA=$($CHECK_CMD)

for PORT in "$@"; do
    # Validate that the port is a number
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "  [ERROR] Invalid port number: $PORT"
        ALL_PASSED=false
        continue
    fi

    # Check if the port is listening using Bash regex matching
    # We look for the port preceded by a colon and followed by whitespace or end of line.
    if [[ "$LISTENING_DATA" =~ :$PORT([[:space:]]|$) ]]; then
        echo "  [PASS] Port $PORT is LISTENING"
    else
        echo "  [FAIL] Port $PORT is NOT listening"
        ALL_PASSED=false
    fi
done

echo "---------------------------------------------------------"
if [ "$ALL_PASSED" = true ]; then
    echo "All specified ports are listening."
    exit 0
else
    echo "One or more ports are NOT listening."
    exit 1
fi
