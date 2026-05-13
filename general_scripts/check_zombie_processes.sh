#!/bin/bash

# Script to detect zombie processes (status 'Z') on the system.
# Zombie processes are completed processes that still have an entry in the process table.
# Usage: ./check_zombie_processes.sh
# Example: ./check_zombie_processes.sh

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0"
    echo "  Detects zombie processes and prints their details."
    exit 1
}

# Help check
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

echo "Checking for zombie processes..."

# Get zombie processes using 'ps'
# 'defunct' is often part of the command name for zombies
ZOMBIES=$(ps aux | awk '{ if ($8 == "Z" || $8 ~ /Z/) print $0 }')

if [ -z "$ZOMBIES" ]; then
    echo "OK: No zombie processes detected."
    exit 0
else
    NUM_ZOMBIES=$(echo "$ZOMBIES" | wc -l)
    echo "WARNING: Found $NUM_ZOMBIES zombie process(es):"
    echo "USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND"
    echo "$ZOMBIES"

    echo -e "\nTo find the parent of a zombie (to potentially kill it and reap the zombie):"
    echo "ps -o ppid= -p <CHILD_PID>"

    exit 1
fi
