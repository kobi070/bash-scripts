#!/bin/bash

# Script to check if Terraform code is properly formatted.
# Useful for CI pipelines to enforce coding standards.
# Usage: ./tf_check_fmt.sh [directory]
# Example: ./tf_check_fmt.sh ./terraform

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [directory]"
    echo "  directory: (optional) Directory to check. Default: current directory"
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

DIR=${1:-.}

echo "Checking Terraform formatting in $DIR..."

if terraform fmt -check -recursive "$DIR"; then
    echo "Success: All Terraform files are properly formatted."
    exit 0
else
    echo "Error: Some Terraform files are not properly formatted. Run 'terraform fmt -recursive' to fix them."
    exit 1
fi
