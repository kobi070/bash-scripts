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

# BOLT Optimization: Run the check command once and store the output.
# This reduces the number of process forks from O(N) to O(1).
LISTENING_PORTS_DATA=$($CHECK_CMD)

for PORT in "$@"; do
    # Validate that the port is a number
    if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
        echo "  [ERROR] Invalid port number: $PORT"
        ALL_PASSED=false
        continue
    fi

    # Check if the port is listening
    # Using Bash built-in regex matching to avoid process forks in the loop.
    # The regex matches :PORT followed by a space (typical for ss/netstat output).
    if [[ "$LISTENING_PORTS_DATA" =~ :$PORT[[:space:]] ]]; then
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
