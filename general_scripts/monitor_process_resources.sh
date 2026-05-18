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

    # Update stats
    MAX_CPU=$(awk "BEGIN {if ($CPU > $MAX_CPU) print $CPU; else print $MAX_CPU}")
    MAX_MEM=$(awk "BEGIN {if ($MEM > $MAX_MEM) print $MEM; else print $MAX_MEM}")
    SUM_CPU=$(awk "BEGIN {print $SUM_CPU + $CPU}")
    SUM_MEM=$(awk "BEGIN {print $SUM_MEM + $MEM}")
    COUNT=$((COUNT + 1))

    sleep "$INTERVAL"
done

echo "--------------------------------------------------------------------------------"
echo "SUMMARY for $COMMAND (PID: $PID):"
if [ "$COUNT" -gt 0 ]; then
    AVG_CPU=$(awk "BEGIN {printf \"%.2f\", $SUM_CPU / $COUNT}")
    AVG_MEM=$(awk "BEGIN {printf \"%.2f\", $SUM_MEM / $COUNT}")
    echo "Average CPU: $AVG_CPU%"
    echo "Peak CPU:    $MAX_CPU%"
    echo "Average MEM: $AVG_MEM%"
    echo "Peak MEM:    $MAX_MEM%"
else
    echo "No samples collected."
fi
echo "--------------------------------------------------------------------------------"
