#!/bin/bash
set -euo pipefail

# Create temporary bin directory for mocks
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Create a mock kubectl
cat <<'MOCK_EOF' > "$MOCK_BIN/kubectl"
#!/bin/bash
if [[ "$*" == *"get node"* ]]; then
    echo "node-1 Ready"
    exit 0
elif [[ "$*" == *"get pdb --all-namespaces"* ]]; then
    echo '{"items": [{"metadata": {"namespace": "ns1", "name": "pdb1"}, "spec": {"selector": {"matchLabels": {"app": "app1"}}}}]}'
elif [[ "$*" == *"get pods --all-namespaces --field-selector spec.nodeName=node-1"* ]]; then
    echo '{
      "items": [
        {"metadata": {"namespace": "ns1", "name": "pod1", "labels": {"app": "app1"}, "ownerReferences": [{"kind": "Deployment"}]}, "spec": {"nodeName": "node-1", "volumes": [{"name": "v1", "emptyDir": {}}]}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns1", "name": "pod2", "labels": {"app": "app1"}, "ownerReferences": [{"kind": "Deployment"}]}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns2", "name": "pod3", "labels": {"app": "app2"}, "ownerReferences": [{"kind": "StatefulSet"}]}, "spec": {"nodeName": "node-1", "volumes": [{"name": "v2", "emptyDir": {}}]}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns2", "name": "pod4", "labels": {"app": "app2"}, "ownerReferences": [{"kind": "StatefulSet"}]}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns3", "name": "pod5", "labels": {"app": "app3"}, "ownerReferences": [{"kind": "ReplicaSet"}]}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns4", "name": "pod6", "labels": {"app": "app4"}, "ownerReferences": [{"kind": "DaemonSet"}]}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns5", "name": "pod7", "labels": {"app": "app5"}, "ownerReferences": [{"kind": "Deployment"}]}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns6", "name": "pod8", "labels": {"app": "app6"}, "ownerReferences": [{"kind": "None"}]}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns7", "name": "pod9", "labels": {"app": "app7"}}, "spec": {"nodeName": "node-1"}, "status": {"phase": "Running"}},
        {"metadata": {"namespace": "ns8", "name": "pod10", "labels": {"app": "app8"}, "ownerReferences": [{"kind": "Job"}]}, "spec": {"nodeName": "node-1", "volumes": [{"name": "v3", "emptyDir": {}}]}, "status": {"phase": "Running"}}
      ]
    }'
fi
MOCK_EOF
chmod +x "$MOCK_BIN/kubectl"

REAL_JQ=$(command -v jq)
REAL_WC=$(command -v wc)
REAL_GREP=$(command -v grep)

cat <<EOF > "$MOCK_BIN/jq"
#!/bin/bash
echo "jq" >> /tmp/forks.log
exec $REAL_JQ "\$@"
EOF
chmod +x "$MOCK_BIN/jq"

cat <<EOF > "$MOCK_BIN/wc"
#!/bin/bash
echo "wc" >> /tmp/forks.log
exec $REAL_WC "\$@"
EOF
chmod +x "$MOCK_BIN/wc"

cat <<EOF > "$MOCK_BIN/grep"
#!/bin/bash
echo "grep" >> /tmp/forks.log
# Ensure grep doesnt fail even if no match, to avoid pipefail killing the script
$REAL_GREP "\$@" || true
EOF
chmod +x "$MOCK_BIN/grep"

count_forks() {
    rm -f /tmp/forks.log
    ./k8s_scripts/k8s_node_drain_helper.sh node-1 > /dev/null 2>&1 || true
    if [ -f /tmp/forks.log ]; then
        $REAL_WC -l < /tmp/forks.log
    else
        echo 0
    fi
}

echo "Measuring process forks for 10 pods (including grep/wc/jq)..."
FORKS=$(count_forks)
echo "Total forks: $FORKS"

# Run it once more to see actual output
echo -e "\nOutput for node-1:"
# Temporarily restore real tools for the final output display to avoid pollution
export PATH="/usr/bin:/bin"
# But we still need our mock kubectl!
mkdir -p /tmp/final_mock
cp "$MOCK_BIN/kubectl" /tmp/final_mock/
export PATH="/tmp/final_mock:$PATH"
./k8s_scripts/k8s_node_drain_helper.sh node-1
rm -rf /tmp/final_mock
