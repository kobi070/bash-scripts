#!/bin/bash

# Script to monitor the CPU and Memory usage of a specific process over time.
# It logs the usage at intervals and provides a final summary.
# Usage: ./monitor_process_resources.sh <pid> [duration_seconds] [interval_seconds]
# Example: ./monitor_process_resources.sh 1234 60 5

set -euo pipefail

# Help function
usage() {
    echo "Usage: $0 <pid> [duration_seconds] [interval_seconds]"
    echo "  pid: The Process ID to monitor"
    echo "  duration_seconds: (optional) How long to monitor. Default: 60"
    echo "  interval_seconds: (optional) Time between samples. Default: 5"
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

PID=$1
DURATION=${2:-60}
INTERVAL=${3:-5}

# Security Pattern: validate numeric input to prevent injection
if [[ ! "$PID" =~ ^[0-9]+$ ]] || [[ ! "$DURATION" =~ ^[0-9]+$ ]] || [[ ! "$INTERVAL" =~ ^[0-9]+$ ]]; then
    echo "Error: PID, duration, and interval must be positive integers."
    exit 1
fi

# Verify PID exists
if ! ps -p "$PID" > /dev/null; then
    echo "Error: Process with PID $PID does not exist."
    exit 1
fi

COMMAND=$(ps -p "$PID" -o comm=)

echo "Monitoring Process: $COMMAND (PID: $PID)"
echo "Duration: ${DURATION}s, Interval: ${INTERVAL}s"
echo "--------------------------------------------------------------------------------"
printf "%-10s | %-10s | %-10s\n" "TIME" "%CPU" "%MEM"
echo "--------------------------------------------------------------------------------"

# Bolt optimization: check for Bash 4.2+ printf %(fmt)T support to avoid 'date' forks
HAS_PRINTF_T=false
if printf "%(%H:%M:%S)T" -1 &>/dev/null; then
    HAS_PRINTF_T=true
fi

SECONDS=0
SAMPLES=""
COUNT=0

while [ "$SECONDS" -lt "$DURATION" ]; do
    # Bolt optimization: consolidate existence check and data extraction into 1 ps call.
    # We use portable flags and remove the header using Bash string manipulation.
    STATS_RAW=$(ps -p "$PID" -o %cpu,%mem 2>/dev/null || true)

    if [ -z "$STATS_RAW" ]; then
        echo "Process $PID terminated."
        break
    fi

    # Optimization/Portability: remove headers using Bash string manipulation (no fork)
    # This is faster than 'tail' or 'sed' and works on both Linux and macOS.
    STATS="${STATS_RAW#*$'\n'}"

    # Read CPU and MEM directly into variables using shell built-in (no fork)
    read -r CPU MEM <<< "$STATS"

    # Use Bash builtin printf %T if supported, otherwise fall back to date
    if [ "$HAS_PRINTF_T" = true ]; then
        printf -v TIME_STR "%(%H:%M:%S)T" -1
    else
        TIME_STR=$(date +"%H:%M:%S")
    fi

    printf "%-10s | %-10s | %-10s\n" "$TIME_STR" "$CPU" "$MEM"

    # Bolt optimization: Store samples for bulk calculation at the end instead of
    # calling 'awk' in every iteration to update statistics.
    SAMPLES+="$CPU $MEM "
    COUNT=$((COUNT + 1))

    sleep "$INTERVAL"
done

echo "--------------------------------------------------------------------------------"
echo "SUMMARY for $COMMAND (PID: $PID):"
if [ "$COUNT" -gt 0 ]; then
    # Bolt optimization: Single bulk awk call to calculate all statistics at once.
    # This replaces multiple awk calls per iteration and multiple awk calls in the summary.
    echo "$SAMPLES" | awk -v count="$COUNT" '
    {
        for (i=1; i<=NF; i+=2) {
            cpu=$i; mem=$(i+1)
            sum_cpu += cpu; sum_mem += mem
            if (cpu > max_cpu) max_cpu = cpu
            if (mem > max_mem) max_mem = mem
        }
        printf "Average CPU: %.2f%%\n", sum_cpu / count
        printf "Peak CPU:    %.2f%%\n", max_cpu
        printf "Average MEM: %.2f%%\n", sum_mem / count
        printf "Peak MEM:    %.2f%%\n", max_mem
    }'
else
    echo "No samples collected."
fi
echo "--------------------------------------------------------------------------------"
