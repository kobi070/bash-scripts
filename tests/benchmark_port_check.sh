#!/bin/bash
set -euo pipefail

# Create a mock ss that returns 1000 ports
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
trap 'rm -rf "$MOCK_BIN"' EXIT

# Optimized mock ss
cat <<'EOF' > "$MOCK_BIN/ss"
#!/bin/bash
printf "LISTEN 0 128 127.0.0.1:%d 0.0.0.0:*\n" {1..1000}
EOF
chmod +x "$MOCK_BIN/ss"

# Prepare 100 ports to check
PORTS=$(seq 1 100)

echo "Benchmarking general_scripts/check_port_listening.sh..."
START_TIME=$(date +%s%N)
./general_scripts/check_port_listening.sh $PORTS > /dev/null
END_TIME=$(date +%s%N)

DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "Execution time: ${DURATION}ms"
