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

# Security check: Ensure inputs are numeric to prevent shell arithmetic injection
if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
    echo "Error: PID must be a positive numeric integer."
    exit 1
fi
if [[ ! "$DURATION" =~ ^[0-9]+$ ]]; then
    echo "Error: DURATION must be a positive numeric integer."
    exit 1
fi
if [[ ! "$INTERVAL" =~ ^[0-9]+$ ]]; then
    echo "Error: INTERVAL must be a positive numeric integer."
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

# Bolt optimization: Detect Bash version to use fast builtins if available
# printf %T was introduced in Bash 4.2
HAS_PRINTF_T=false
if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2) )); then
    HAS_PRINTF_T=true
fi

SECONDS=0
COUNT=0
ALL_CPU=""
ALL_MEM=""

while [ "$SECONDS" -lt "$DURATION" ]; do
    # Bolt optimization: Combine existence check and data extraction into a single ps call.
    # We use standard portable -o %cpu,%mem and skip the header line using Bash manipulation.
    # This avoids the Linux-specific %cpu= syntax while still saving a process fork (tail).
    STATS_RAW=$(ps -p "$PID" -o %cpu,%mem 2>/dev/null || true)

    if [ -z "$STATS_RAW" ]; then
        echo "Process $PID terminated."
        break
    fi

    # Extract the second line (data) from the ps output using Bash parameter expansion
    # This replaces 'tail -n +2'
    STATS="${STATS_RAW#*$'\n'}"

    # Bolt optimization: Use read builtin to parse ps output
    read -r CPU MEM <<< "$STATS"

    # Bolt optimization: Use Bash builtin printf %T for timestamp if supported, else fallback to date
    if [ "$HAS_PRINTF_T" = true ]; then
        printf -v TIME_STR "%(%H:%M:%S)T" -1
    else
        TIME_STR=$(date +"%H:%M:%S")
    fi

    printf "%-10s | %-10s | %-10s\n" "$TIME_STR" "$CPU" "$MEM"

    # Bolt optimization: Accumulate raw data for a single bulk calculation at the end,
    # avoiding 4 awk forks per iteration.
    ALL_CPU+="$CPU "
    ALL_MEM+="$MEM "
    COUNT=$((COUNT + 1))

    sleep "$INTERVAL"
done

echo "--------------------------------------------------------------------------------"
echo "SUMMARY for $COMMAND (PID: $PID):"
if [ "$COUNT" -gt 0 ]; then
    # Bolt optimization: Perform all summary calculations in a single awk call.
    # This reduces process forks from 4*N to 1.
    STATS_OUT=$(echo "$ALL_CPU $ALL_MEM" | awk -v count="$COUNT" '
    {
        for(i=1; i<=count; i++) {
            cpu=$(i);
            sum_cpu += cpu;
            if (cpu > max_cpu) max_cpu = cpu;
        }
        for(i=count+1; i<=2*count; i++) {
            mem=$(i);
            sum_mem += mem;
            if (mem > max_mem) max_mem = mem;
        }
        printf "%.2f %.2f %.2f %.2f", sum_cpu/count, max_cpu, sum_mem/count, max_mem
    }')

    read -r AVG_CPU MAX_CPU AVG_MEM MAX_MEM <<< "$STATS_OUT"

    echo "Average CPU: $AVG_CPU%"
    echo "Peak CPU:    $MAX_CPU%"
    echo "Average MEM: $AVG_MEM%"
    echo "Peak MEM:    $MAX_MEM%"
else
    echo "No samples collected."
fi
echo "--------------------------------------------------------------------------------"
