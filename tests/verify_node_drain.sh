#!/bin/bash
set -euo pipefail

# Create temporary bin directory for mocks
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

echo "Verifying k8s_node_drain_helper.sh..."

# Mock kubectl
cat <<'EOF' > "$MOCK_BIN/kubectl"
#!/bin/bash
if [[ "$*" == *"get node"* ]]; then
  echo "node-1"
elif [[ "$*" == *"get pods"* ]]; then
  # Return two pods: one with local storage and PDB, one without
  echo '{
    "items": [
      {
        "metadata": {
          "namespace": "default",
          "name": "pod-1",
          "labels": {"app": "web"},
          "ownerReferences": [{"kind": "Deployment"}]
        },
        "spec": {
          "volumes": [{"name": "cache", "emptyDir": {}}]
        },
        "status": {"phase": "Running"}
      },
      {
        "metadata": {
          "namespace": "default",
          "name": "pod-2",
          "labels": {"app": "db"},
          "ownerReferences": []
        },
        "spec": {
          "volumes": [{"name": "data", "hostPath": {"path": "/data"}}]
        },
        "status": {"phase": "Running"}
      }
    ]
  }'
elif [[ "$*" == *"get pdb"* ]]; then
  echo '{
    "items": [
      {
        "metadata": {"namespace": "default", "name": "web-pdb"},
        "spec": {"selector": {"matchLabels": {"app": "web"}}}
      }
    ]
  }'
fi
EOF
chmod +x "$MOCK_BIN/kubectl"

OUTPUT=$(./k8s_scripts/k8s_node_drain_helper.sh node-1)
echo "$OUTPUT"

# Verify correctness
if echo "$OUTPUT" | grep -q "default/pod-1" && \
   echo "$OUTPUT" | grep -q "Deployment" && \
   echo "$OUTPUT" | grep -q "OK (1)" && \
   echo "$OUTPUT" | grep -q "YES"; then
    echo "✔ pod-1 correctly identified"
else
    echo "✖ pod-1 verification failed"
    exit 1
fi

if echo "$OUTPUT" | grep -q "default/pod-2" && \
   echo "$OUTPUT" | grep -q "None" && \
   echo "$OUTPUT" | grep -q "MISSING" && \
   echo "$OUTPUT" | grep -q "NO"; then
    echo "✔ pod-2 correctly identified"
else
    echo "✖ pod-2 verification failed"
    exit 1
fi

echo "All tests passed!"
