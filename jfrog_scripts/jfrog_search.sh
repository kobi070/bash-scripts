#!/bin/bash

# Script to search for artifacts in JFrog Artifactory using the CLI.
# Usage: ./jfrog_search.sh <pattern>
# Example: ./jfrog_search.sh "generic-local/my-app/*.zip"

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <pattern>"
    echo "  pattern: The search pattern in Artifactory (e.g., repo/path/to/artifact*)"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI (jf or jfrog) is not installed or not in PATH."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

# Input validation
if [ "$#" -ne 1 ]; then
    usage
fi

PATTERN=$1

echo "Searching for artifacts matching: $PATTERN"

# Perform the search and output as JSON
$JF_BIN rt search "$PATTERN"
