#!/bin/bash
# set -euo pipefail # Removing pipefail to handle grep potentially not finding something in some tests if I add negative tests, but I want to be careful.

# Create temporary bin directory for mocks
MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

echo "Starting logic verification with mocks..."

# --- 1. Mock for k8s_audit_pdb.sh ---
cat <<'EOF' > "$MOCK_BIN/kubectl"
#!/bin/bash
if [[ "$*" == *"get pdb"* ]]; then
  echo '{"items": [{"metadata": {"namespace": "prod", "name": "app-pdb"}, "spec": {"selector": {"matchLabels": {"app": "web"}}}}]}'
elif [[ "$*" == *"get deployment,statefulset"* ]]; then
  echo '{"items": [{"kind": "Deployment", "metadata": {"namespace": "prod", "name": "web-deploy"}, "spec": {"template": {"metadata": {"labels": {"app": "web"}}}}}, {"kind": "StatefulSet", "metadata": {"namespace": "prod", "name": "db-sts"}, "spec": {"template": {"metadata": {"labels": {"app": "db"}}}}}]}'
fi
EOF
chmod +x "$MOCK_BIN/kubectl"

echo "Testing k8s_audit_pdb.sh..."
if ./k8s_scripts/k8s_audit_pdb.sh prod 2>&1 | grep -q "db-sts"; then
    echo "  ✔ Found missing PDB for db-sts"
else
    echo "  ✖ Failed to find missing PDB"
    exit 1
fi

# --- 2. Mock for docker_root_check.sh ---
cat <<'EOF' > "$MOCK_BIN/docker"
#!/bin/bash
if [[ "$*" == "ps -q" ]]; then
  echo "id1"
  echo "id2"
elif [[ "$*" == *"inspect"* ]]; then
  echo "/root-box|root"
  echo "/user-box|1000"
fi
EOF
chmod +x "$MOCK_BIN/docker"

echo "Testing docker_root_check.sh..."
if ./docker_scripts/docker_root_check.sh 2>&1 | grep -q "root-box"; then
    echo "  ✔ Found root container"
else
    echo "  ✖ Failed to find root container"
    exit 1
fi

# --- 3. Mock for aws_iam_key_age.sh ---
cat <<'EOF' > "$MOCK_BIN/aws"
#!/bin/bash
if [[ "$*" == *"list-users"* ]]; then
  echo "jules-user"
elif [[ "$*" == *"list-access-keys"* ]]; then
  # Create a date in the past
  OLD_DATE=$(date -u -d "100 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-100d +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"AccessKeyMetadata\": [{\"UserName\": \"jules-user\", \"AccessKeyId\": \"AKIA123\", \"Status\": \"Active\", \"CreateDate\": \"$OLD_DATE\"}]}"
fi
EOF
chmod +x "$MOCK_BIN/aws"

echo "Testing aws_iam_key_age.sh..."
if ./aws_scripts/aws_iam_key_age.sh 90 2>&1 | grep -q "AKIA123"; then
    echo "  ✔ Found old IAM key"
else
    echo "  ✖ Failed to find old IAM key"
    exit 1
fi

# --- 4. Mock for gh_workflow_stats.sh ---
cat <<'EOF' > "$MOCK_BIN/gh"
#!/bin/bash
if [[ "$*" == *"api"* ]]; then
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  START=$(date -u -d "1 minute ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-1m +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"workflow_runs\": [{\"status\": \"completed\", \"conclusion\": \"success\", \"updated_at\": \"$NOW\", \"run_started_at\": \"$START\", \"created_at\": \"$NOW\", \"html_url\": \"http://example.com/1\"}, {\"status\": \"completed\", \"conclusion\": \"failure\", \"updated_at\": \"$NOW\", \"run_started_at\": \"$START\", \"created_at\": \"$NOW\", \"html_url\": \"http://example.com/2\"}]}"
fi
EOF
chmod +x "$MOCK_BIN/gh"

echo "Testing gh_workflow_stats.sh..."
if ./github_scripts/gh_workflow_stats.sh owner/repo main.yml 2>&1 | grep -q "Success Rate:  50%"; then
    echo "  ✔ Calculated correct success rate"
else
    echo "  ✖ Failed success rate check"
    exit 1
fi

# --- 5. Mock for argocd_app_diff.sh ---
cat <<'EOF' > "$MOCK_BIN/argocd"
#!/bin/bash
if [[ "$*" == *"account get-user-info"* ]]; then
  exit 0
elif [[ "$*" == *"app diff"* ]]; then
  echo "--- cluster-state"
  echo "+++ git-state"
  exit 1
fi
EOF
chmod +x "$MOCK_BIN/argocd"

echo "Testing argocd_app_diff.sh..."
if ./argocd_scripts/argocd_app_diff.sh my-app 2>&1 | grep -q "git-state"; then
    echo "  ✔ Captured diff output"
else
    echo "  ✖ Failed to capture diff"
    exit 1
fi

echo "All logic verifications passed!"
