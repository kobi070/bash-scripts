#!/bin/bash
# Script to manage specified processes and audit actions.
set -euo pipefail

usage() {
    echo "Usage: $0"
    exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; fi

echo "Welcome to the process management menu"
processes=("google-chrome" "firefox" "geany")
ts=$(date '+%Y%m%d%H%M%S')
audit_file="${ts}.audit.txt"

read -p "Would you like to kill all monitored processes? [y/n] " killall
if [[ "$killall" == "y" ]]; then
    for process in "${processes[@]}"; do
        if pgrep "$process" > /dev/null; then
            pkill "$process"
            echo "$(date): Killed $process (bulk)" >> "$audit_file"
        fi
    done
fi

for process in "${processes[@]}"; do
    if pgrep "$process" > /dev/null; then
        read -p "$process is running. Would you like to kill it? (y/n) " answer
        if [[ "$answer" == "y" ]]; then
            pkill "$process"
            echo "$(date): Killed $process" >> "$audit_file"
        else
            echo "$(date): User chose not to kill $process" >> "$audit_file"
        fi
    else
        read -p "$process is not running. Would you like to start it? (y/n) " choice
        if [[ "$choice" == "y" ]]; then
            echo "$(date): User started $process" >> "$audit_file"
            "$process" &
        else
            echo "$(date): User did not start $process" >> "$audit_file"
        fi
    fi
done
echo "Audit log saved to $audit_file"
