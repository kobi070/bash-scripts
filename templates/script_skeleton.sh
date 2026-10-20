#!/bin/bash

# <script_name>.sh — one-line description of what the script does.
# Longer description: what problem it solves, what it reads/changes, and any
# notable behavior (read-only? idempotent? destructive with confirmation?).
# Usage: ./<script_name>.sh [--flag <value>] [positional]
# Example: ./<script_name>.sh --region us-east-1

set -euo pipefail

usage() {
    echo "Usage: $0 [--flag <value>] [positional]"
    echo ""
    echo "Options:"
    echo "  --flag <value>   What the flag does. Default: <default>."
    echo "  -h, --help       Show this help message."
    exit 1
}

# --- Required tools check (fail fast, before doing any work) ---
for tool in aws jq; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool is not installed or not in PATH."
        exit 1
    fi
done

# --- Argument parsing ---
FLAG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --flag)
            [[ -n "${2:-}" ]] || { echo "Error: --flag requires a value."; usage; }
            FLAG="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Unknown option: $1"
            usage
            ;;
    esac
done

# --- Main logic ---
# Keep functions small and single-purpose. Quote every expansion.
# Prefer a single CLI call + jq pipeline over loops of CLI calls.
main() {
    echo "FLAG=${FLAG:-<unset>}"
}

main
