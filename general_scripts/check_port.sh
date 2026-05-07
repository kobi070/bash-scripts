#!/bin/bash
set -euo pipefail

# This script checks if a specific port is in use.

usage() {
    echo "Usage: $0 <port_number>"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

port=$1

if command -v ss >/dev/null 2>&1; then
    echo "Checking port $port using ss..."
    ss -tulpn | grep ":$port " || echo "Port $port is free."
elif command -v lsof >/dev/null 2>&1; then
    echo "Checking port $port using lsof..."
    lsof -i ":$port" || echo "Port $port is free."
else
    echo "Error: Neither 'ss' nor 'lsof' is installed."
    exit 1
fi
