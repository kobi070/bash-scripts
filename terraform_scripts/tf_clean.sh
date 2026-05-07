#!/bin/bash
set -euo pipefail

# This script recursively removes .terraform directories and lock files to clean up Terraform projects.

echo "Searching for .terraform directories and .terraform.lock.hcl files..."

find . -type d -name ".terraform" -prune -exec echo "Removing {}" \; -exec rm -rf {} +
find . -type f -name ".terraform.lock.hcl" -exec echo "Removing {}" \; -exec rm -f {} +

echo "✅ Cleanup complete."
