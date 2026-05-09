#!/bin/bash
set -euo pipefail

# This script manages JFrog Release Bundles.
# Usage: ./jf_release_bundle.sh create <name> <version> <spec_file>
#        ./jf_release_bundle.sh sign <name> <version>
#        ./jf_release_bundle.sh promote <name> <version> <target_env>

if ! command -v jf &> /dev/null && ! command -v jfrog &> /dev/null; then
    echo "Error: JFrog CLI not found."
    exit 1
fi

JF_BIN=$(command -v jf || command -v jfrog)

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 create <name> <version> <spec_file>"
    echo "       $0 sign <name> <version>"
    echo "       $0 promote <name> <version> <target_env>"
    exit 1
fi

COMMAND=$1

case "$COMMAND" in
    create)
        "$JF_BIN" release-bundle-create "$2" "$3" --spec="$4"
        ;;
    sign)
        "$JF_BIN" release-bundle-sign "$2" "$3"
        ;;
    promote)
        "$JF_BIN" release-bundle-promote "$2" "$3" "$4"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
esac
