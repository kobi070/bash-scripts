#!/bin/bash

# Script to find all directories containing Terraform files and run 'terraform validate' in each.
# Useful for pre-commit hooks or CI pipelines to ensure all modules are valid.
# Usage: ./tf_validate_all.sh [root_directory]
# Example: ./tf_validate_all.sh ./infrastructure

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [root_directory]"
    echo "  root_directory: (optional) The directory to start searching from. Default: current directory"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

# Check for required tools
if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed or not in PATH."
    exit 1
fi

ROOT_DIR=${1:-.}

echo "Finding Terraform modules in $ROOT_DIR..."

# Find all directories containing .tf files, excluding hidden directories like .terraform
MODULES=$(find "$ROOT_DIR" -type f -name "*.tf" -not -path "*/.*" -exec dirname {} + | sort -u)

if [ -z "$MODULES" ]; then
    echo "No Terraform files found."
    exit 0
fi

FAILED_MODULES=()

for MODULE in $MODULES; do
    echo "------------------------------------------------------------"
    echo "Validating module in: $MODULE"

    # We might need terraform init if it hasn't been run,
    # but validate usually works if .terraform is present or if no providers are needed.
    if (cd "$MODULE" && terraform validate); then
        echo "  [OK] Module is valid."
    else
        echo "  [FAIL] Module validation failed."
        FAILED_MODULES+=("$MODULE")
    fi
done

echo "------------------------------------------------------------"
if [ ${#FAILED_MODULES[@]} -ne 0 ]; then
    echo "Error: The following modules failed validation:"
    for MODULE in "${FAILED_MODULES[@]}"; do
        echo "  - $MODULE"
    done
    exit 1
fi

echo "All Terraform modules validated successfully."
exit 0
