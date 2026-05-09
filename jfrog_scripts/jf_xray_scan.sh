#!/bin/bash
set -euo pipefail

# This script performs a security scan using JFrog Xray.
# Usage: ./jf_xray_scan.sh <path_to_scan>

# Verify JFrog CLI existence
if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI ('jf' or 'jfrog') not found."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_scan>"
    exit 1
fi

SCAN_PATH="$1"

echo "Running Xray scan on $SCAN_PATH..."
"$JF_BIN" scan "$SCAN_PATH"
