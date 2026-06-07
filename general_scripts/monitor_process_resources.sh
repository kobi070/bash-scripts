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

# Security check: Ensure PID, DURATION and INTERVAL are numeric integers to prevent shell arithmetic injection
if [[ ! "$PID" =~ ^[0-9]+$ ]]; then
    echo "Error: PID must be a numeric integer."
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

# Bolt optimization: Use Bash builtin $SECONDS to avoid repetitive 'date' process forks
SECONDS=0
MAX_CPU=0
MAX_MEM=0
SUM_CPU=0
SUM_MEM=0
COUNT=0

while [ "$SECONDS" -lt "$DURATION" ]; do
    # Verify PID still exists
    if ! ps -p "$PID" > /dev/null; then
        echo "Process $PID terminated."
        break
    fi

    # Optimized: use a single awk command to extract CPU and MEM
    # ps -p $PID -o %cpu,%mem --no-headers
    # Some ps versions might not support --no-headers, use tail -n +2
    STATS=$(ps -p "$PID" -o %cpu,%mem | tail -n +2)
    CPU=$(echo "$STATS" | awk '{print $1}')
    MEM=$(echo "$STATS" | awk '{print $2}')

    TIME_STR=$(date +"%H:%M:%S")
    printf "%-10s | %-10s | %-10s\n" "$TIME_STR" "$CPU" "$MEM"

    # Update stats safely by passing variables to awk
    MAX_CPU=$(awk -v cpu="$CPU" -v max_cpu="$MAX_CPU" 'BEGIN {if (cpu > max_cpu) print cpu; else print max_cpu}')
    MAX_MEM=$(awk -v mem="$MEM" -v max_mem="$MAX_MEM" 'BEGIN {if (mem > max_mem) print mem; else print max_mem}')
    SUM_CPU=$(awk -v sum_cpu="$SUM_CPU" -v cpu="$CPU" 'BEGIN {print sum_cpu + cpu}')
    SUM_MEM=$(awk -v sum_mem="$SUM_MEM" -v mem="$MEM" 'BEGIN {print sum_mem + mem}')
    COUNT=$((COUNT + 1))

    sleep "$INTERVAL"
done

echo "--------------------------------------------------------------------------------"
echo "SUMMARY for $COMMAND (PID: $PID):"
if [ "$COUNT" -gt 0 ]; then
    AVG_CPU=$(awk -v sum="$SUM_CPU" -v count="$COUNT" 'BEGIN {printf "%.2f", sum / count}')
    AVG_MEM=$(awk -v sum="$SUM_MEM" -v count="$COUNT" 'BEGIN {printf "%.2f", sum / count}')
    echo "Average CPU: $AVG_CPU%"
    echo "Peak CPU:    $MAX_CPU%"
    echo "Average MEM: $AVG_MEM%"
    echo "Peak MEM:    $MAX_MEM%"
else
    echo "No samples collected."
fi
echo "--------------------------------------------------------------------------------"
