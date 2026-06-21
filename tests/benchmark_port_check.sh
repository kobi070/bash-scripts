#!/bin/bash
# benchmark_port_check.sh - Benchmarks the port listening check script.

# Create temporary bin directory for mocks
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Create a mock ss command that returns 100 listening ports
cat <<'EOF' > "$MOCK_BIN/ss"
#!/bin/bash
for i in {1..100}; do
  echo "LISTEN 0 128 127.0.0.1:$i 0.0.0.0:*"
done
EOF
chmod +x "$MOCK_BIN/ss"

# Generate a list of 100 ports to check
PORTS=$(seq 1 100)

echo "Running benchmark for general_scripts/check_port_listening.sh with 100 ports..."

# Use time command to measure execution time
# We use a subshell to ensure the trap is hit and we get a clean measurement
time ./general_scripts/check_port_listening.sh $PORTS > /dev/null
