#!/bin/bash

# Script to detect unpinned provider versions in Terraform (.tf) files.
# It recursively scans the current directory or a specified path for missing 'version' constraints
# in 'required_providers' blocks.
# Usage: ./tf_provider_version_check.sh [path]
# Example: ./tf_provider_version_check.sh ./infrastructure

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 [path]"
    echo "  path: (optional) The directory to scan. Default: current directory"
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

SEARCH_PATH=${1:-.}

if [[ ! -d "$SEARCH_PATH" ]]; then
    echo "Error: Directory '$SEARCH_PATH' not found."
    exit 1
fi

echo "Scanning for unpinned Terraform provider versions in '$SEARCH_PATH'..."

UNPINNED_FOUND=0

# Use find to get all .tf files
while IFS= read -r -d '' file; do
    # Enhanced awk state machine to find provider blocks without version constraints
    UNPINNED=$(awk '
        /required_providers \{/ { in_required_block=1; next }
        in_required_block && /^[[:space:]]+[a-z0-9_-]+ = \{/ {
            # Start of a provider block inside required_providers
            if (provider != "" && has_version == 0) {
                print provider
            }
            provider = $1
            has_version = 0
            in_provider_block = 1
            next
        }
        in_provider_block && /version[[:space:]]*=/ {
            has_version = 1
        }
        in_provider_block && /\}/ {
            # End of a provider block
            if (provider != "" && has_version == 0) {
                print provider
            }
            provider = ""
            has_version = 0
            in_provider_block = 0
            next
        }
        in_required_block && /\}/ && !in_provider_block {
            # End of required_providers block
            in_required_block = 0
        }
    ' "$file")

    if [[ -n "$UNPINNED" ]]; then
        echo "Found unpinned providers in $file:"
        echo "$UNPINNED" | sed 's/^/  - /'
        UNPINNED_FOUND=$((UNPINNED_FOUND + 1))
    fi
done < <(find "$SEARCH_PATH" -type f -name "*.tf" -print0)

if [[ $UNPINNED_FOUND -eq 0 ]]; then
    echo "OK: All detected providers appear to have version constraints (or no providers found)."
else
    echo "WARNING: Found $UNPINNED_FOUND file(s) with unpinned provider versions."
fi
