#!/bin/bash
MOCK_BIN=$(mktemp -d)
trap 'rm -rf "$MOCK_BIN"' EXIT
cat <<'MOCK' > "$MOCK_BIN/kubectl"
#!/bin/bash
if [[ "$*" == *"get node"* ]]; then
  echo "node1 Ready"
elif [[ "$*" == *"get pods --all-namespaces --field-selector spec.nodeName=node1"* ]]; then
  echo '{"items": ['
  for i in {1..10}; do
    echo "{\"metadata\": {\"namespace\": \"ns$i\", \"name\": \"pod$i\", \"labels\": {\"app\": \"app$i\"}, \"ownerReferences\": [{\"kind\": \"Deployment\"}]}, \"status\": {\"phase\": \"Running\"}, \"spec\": {\"volumes\": [{\"emptyDir\": {}}]}},"
  done | sed '$ s/,$//'
  echo ']}'
elif [[ "$*" == *"get pdb --all-namespaces"* ]]; then
  echo '{"items": [{"metadata": {"namespace": "ns1", "name": "pdb1"}, "spec": {"selector": {"matchLabels": {"app": "app1"}}}}, {"metadata": {"namespace": "ns2", "name": "pdb2"}, "spec": {"selector": {"matchLabels": {"app": "app2"}}}}]}'
fi
MOCK
chmod +x "$MOCK_BIN/kubectl"
PATH="$MOCK_BIN:$PATH"

echo "Current process forks (10 pods):"
strace -f -e trace=execve ./k8s_scripts/k8s_node_drain_helper.sh node1 2>&1 | grep execve | wc -l

./k8s_scripts/k8s_node_drain_helper.sh node1
