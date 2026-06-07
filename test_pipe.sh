#!/bin/bash
set -euo pipefail
./general_scripts/monitor_process_resources.sh $$ 1 1 | grep SUMMARY
echo "Exit code: $?"
