#!/bin/bash

# Script to validate that required environment variables are set and not empty.
# Useful for CI/CD pre-flight checks to ensure secrets and configs are available.
# Usage: ./validate_env_vars.sh VAR1 VAR2 VAR3 ...
# Example: ./validate_env_vars.sh DOCKER_USERNAME DOCKER_PASSWORD KUBECONFIG

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 VAR1 [VAR2 ... VARN]"
    echo "  VARx: The name of the environment variable to check."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Input validation
if [ "$#" -lt 1 ]; then
    usage
fi

MISSING_VARS=()

echo "Validating environment variables..."

for VAR_NAME in "$@"; do
    # Security check: Ensure VAR_NAME is a valid shell identifier to prevent command injection via indirect expansion
    if [[ ! "$VAR_NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "  [FAIL] $VAR_NAME is NOT a valid environment variable name."
        MISSING_VARS+=("$VAR_NAME")
        continue
    fi

    if [ -z "${!VAR_NAME:-}" ]; then
        echo "  [FAIL] $VAR_NAME is NOT set or is empty."
        MISSING_VARS+=("$VAR_NAME")
    else
        echo "  [OK]   $VAR_NAME is set."
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "Error: The following required environment variables are missing: ${MISSING_VARS[*]}"
    exit 1
fi

echo "All environment variables are validated successfully."
exit 0
