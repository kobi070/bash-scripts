#!/bin/bash
set -euo pipefail

# Use a real PID that exists for testing
MY_PID=$$

echo "Testing valid input..."
./general_scripts/monitor_process_resources.sh "$MY_PID" 1 1 > test_output.txt 2>&1
if grep -q "SUMMARY" test_output.txt; then
    echo "  ✔ Valid input accepted"
else
    echo "  ✖ Valid input failed"
    cat test_output.txt
    rm test_output.txt
    exit 1
fi
rm test_output.txt

echo "Testing invalid PID (injection attempt)..."
./general_scripts/monitor_process_resources.sh "$MY_PID; touch VULN_PID" 1 1 > test_output.txt 2>&1 || true
if grep -q "Error: PID must be a numeric integer" test_output.txt; then
    echo "  ✔ Malicious PID rejected"
else
    echo "  ✖ Malicious PID NOT rejected"
    cat test_output.txt
    rm test_output.txt
    exit 1
fi
rm test_output.txt

echo "Testing invalid DURATION (injection attempt)..."
./general_scripts/monitor_process_resources.sh "$MY_PID" "1; touch VULN_DUR" 1 > test_output.txt 2>&1 || true
if grep -q "Error: DURATION must be a positive numeric integer" test_output.txt; then
    echo "  ✔ Malicious DURATION rejected"
else
    echo "  ✖ Malicious DURATION NOT rejected"
    cat test_output.txt
    rm test_output.txt
    exit 1
fi
rm test_output.txt

echo "Testing invalid INTERVAL (injection attempt)..."
./general_scripts/monitor_process_resources.sh "$MY_PID" 1 "1; touch VULN_INT" > test_output.txt 2>&1 || true
if grep -q "Error: INTERVAL must be a positive numeric integer" test_output.txt; then
    echo "  ✔ Malicious INTERVAL rejected"
else
    echo "  ✖ Malicious INTERVAL NOT rejected"
    cat test_output.txt
    rm test_output.txt
    exit 1
fi
rm test_output.txt

# Double check that no files were created
if [ -f VULN_PID ] || [ -f VULN_DUR ] || [ -f VULN_INT ]; then
    echo "  ✖ VULNERABILITY EXPLOITED: Malicious command executed!"
    rm -f VULN_PID VULN_DUR VULN_INT
    exit 1
else
    echo "  ✔ No side effects from malicious inputs"
fi

echo "All security tests passed!"
