#!/bin/bash
# tests/benchmark_port_check.sh
# Benchmarks check_port_listening.sh by checking 50 ports.

set -euo pipefail

# Create a mock bin directory
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"

# Create a mock 'ss' that adds a small delay to simulate system overhead
cat <<EOF > "$MOCK_BIN/ss"
#!/bin/bash
sleep 0.01
echo "LISTEN 0 128 127.0.0.1:8080 0.0.0.0:*"
echo "LISTEN 0 128 127.0.0.1:9090 0.0.0.0:*"
EOF
chmod +x "$MOCK_BIN/ss"

# Generate 50 ports
PORTS=$(seq 8000 8049)

echo "Benchmarking check_port_listening.sh with 50 ports..."
START_TIME=$(python3 -c 'import time; print(time.time())')

# Run the script and discard output
./general_scripts/check_port_listening.sh $PORTS > /dev/null 2>&1 || true

END_TIME=$(python3 -c 'import time; print(time.time())')
DURATION=$(python3 -c "print($END_TIME - $START_TIME)")

echo "Total Duration: ${DURATION}s"

# Cleanup
rm -rf "$MOCK_BIN"
