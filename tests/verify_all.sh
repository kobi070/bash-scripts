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

# --- 3. Mock for AWS IAM scripts ---
cat <<'EOF' > "$MOCK_BIN/aws"
#!/bin/bash
if [[ "$*" == *"list-users"* ]]; then
  echo "jules-user"
elif [[ "$*" == *"list-access-keys"* ]]; then
  # Create a date in the past
  OLD_DATE=$(date -u -d "100 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-100d +"%Y-%m-%dT%H:%M:%SZ")
  echo "{\"AccessKeyMetadata\": [{\"UserName\": \"jules-user\", \"AccessKeyId\": \"AKIA123\", \"Status\": \"Active\", \"CreateDate\": \"$OLD_DATE\"}]}"
elif [[ "$*" == *"generate-credential-report"* ]]; then
  echo "COMPLETE"
elif [[ "$*" == *"get-credential-report"* ]]; then
  # Mock CSV: user,arn,user_creation_time,password_enabled,password_last_used,...
  # access_key_1_last_used_date is field 11, access_key_2_last_used_date is field 16
  CSV_CONTENT="user,arn,user_creation_time,password_enabled,password_last_used,password_last_changed,password_next_rotation,mfa_active,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_1_last_used_region,access_key_1_last_used_service,access_key_2_active,access_key_2_last_rotated,access_key_2_last_used_date\njules-user,arn:aws:iam::123456789012:user/jules-user,2023-01-01T00:00:00+00:00,true,2023-11-01T00:00:00+00:00,2023-01-01T00:00:00+00:00,N/A,true,true,2023-01-01T00:00:00+00:00,2023-11-02T00:00:00+00:00,us-east-1,ec2,false,N/A,N/A"
  echo -e "$CSV_CONTENT" | base64 | tr -d '\n'
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

echo "Testing aws_list_iam_users_last_login.sh..."
if ./aws_scripts/aws_list_iam_users_last_login.sh 2>&1 | grep -q "2023-11-02T00:00:00+00:00"; then
    echo "  ✔ Found last key usage in credential report"
else
    echo "  ✖ Failed to find last key usage"
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

# --- 6. Mock for k8s_resource_usage_percentage.sh ---
cat <<'EOF' > "$MOCK_BIN/kubectl"
#!/bin/bash
if [[ "$*" == *"top pod --all-namespaces"* ]]; then
  echo "prod web-pod 500m 256Mi"
elif [[ "$*" == *"top pod -n prod"* ]]; then
  echo "web-pod 500m 256Mi"
elif [[ "$*" == *"get pods"* ]]; then
  echo '{"items": [{"metadata": {"namespace": "prod", "name": "web-pod"}, "spec": {"containers": [{"resources": {"limits": {"cpu": "1000m", "memory": "512Mi"}}}]}}]}'
fi
EOF
chmod +x "$MOCK_BIN/kubectl"

echo "Testing k8s_resource_usage_percentage.sh (all-namespaces)..."
if ./k8s_scripts/k8s_resource_usage_percentage.sh all 2>&1 | grep -q "50.0%"; then
    echo "  ✔ Calculated correct usage percentage (all-namespaces)"
else
    echo "  ✖ Failed usage percentage check (all-namespaces)"
    exit 1
fi

echo "Testing k8s_resource_usage_percentage.sh (namespace prod)..."
if ./k8s_scripts/k8s_resource_usage_percentage.sh prod 2>&1 | grep -q "50.0%"; then
    echo "  ✔ Calculated correct usage percentage (namespace prod)"
else
    echo "  ✖ Failed usage percentage check (namespace prod)"
    exit 1
fi

# --- 7. Mock for gh_list_merged_pr_authors.sh ---
cat <<'EOF' > "$MOCK_BIN/gh"
#!/bin/bash
if [[ "$*" == *"pr list"* ]]; then
  echo '[{"author": {"login": "jules-dev"}, "mergedAt": "2023-11-01T00:00:00Z"}, {"author": {"login": "bolt-bot"}, "mergedAt": "2023-11-02T00:00:00Z"}]'
fi
EOF
chmod +x "$MOCK_BIN/gh"

echo "Testing gh_list_merged_pr_authors.sh..."
if ./github_scripts/gh_list_merged_pr_authors.sh owner/repo 2023-01-01 2>&1 | grep -q "jules-dev"; then
    echo "  ✔ Found merged PR author"
else
    echo "  ✖ Failed to find author"
    exit 1
fi

# --- 8. Mock for check_port_listening.sh ---
cat <<'EOF' > "$MOCK_BIN/ss"
#!/bin/bash
echo "LISTEN 0 128 127.0.0.1:8080 0.0.0.0:*"
EOF
chmod +x "$MOCK_BIN/ss"

echo "Testing check_port_listening.sh..."
if ./general_scripts/check_port_listening.sh 8080 2>&1 | grep -q "PASS"; then
    echo "  ✔ Detected listening port"
else
    echo "  ✖ Failed to detect port"
    exit 1
fi

# --- 9. Mock for docker_image_vulnerability_summary.sh ---
cat <<'EOF' > "trivy_mock.json"
{
  "Results": [
    {
      "Vulnerabilities": [
        {"Severity": "CRITICAL"},
        {"Severity": "HIGH"},
        {"Severity": "HIGH"}
      ]
    }
  ]
}
EOF

echo "Testing docker_image_vulnerability_summary.sh..."
if ./docker_scripts/docker_image_vulnerability_summary.sh trivy_mock.json 2>&1 | grep -q "CRITICAL: 1"; then
    echo "  ✔ Summarized vulnerabilities correctly"
else
    echo "  ✖ Failed vulnerability summary"
    rm trivy_mock.json
    exit 1
fi
rm trivy_mock.json

# --- 10. Mock for aws_ec2_public_ip_checker.sh ---
cat <<'EOF' > "$MOCK_BIN/aws"
#!/bin/bash
if [[ "$*" == *"ec2 describe-instances"* ]]; then
  echo '[[{"InstanceId": "i-123", "PublicIp": "1.2.3.4", "State": "running", "Name": "prod-web"}]]'
fi
EOF
chmod +x "$MOCK_BIN/aws"

echo "Testing aws_ec2_public_ip_checker.sh..."
if ./aws_scripts/aws_ec2_public_ip_checker.sh 2>&1 | grep -q "1.2.3.4"; then
    echo "  ✔ Found public IP"
else
    echo "  ✖ Failed to find public IP"
    exit 1
fi

# --- 11. Mock for k8s_configmap_secret_sync_check.sh ---
cat <<'EOF' > "$MOCK_BIN/kubectl"
#!/bin/bash
if [[ "$*" == *"get deployment,statefulset"* ]]; then
  echo '{"items": [{"kind": "Deployment", "metadata": {"namespace": "prod", "name": "web"}, "spec": {"template": {"spec": {"containers": [{"env": [{"name": "FOO", "valueFrom": {"configMapKeyRef": {"name": "missing-cm", "key": "foo"}}}]}]}}}}]}'
elif [[ "$*" == *"get configmap"* ]]; then
  echo '{"items": []}'
elif [[ "$*" == *"get secret"* ]]; then
  echo '{"items": []}'
fi
EOF
chmod +x "$MOCK_BIN/kubectl"

echo "Testing k8s_configmap_secret_sync_check.sh..."
if ./k8s_scripts/k8s_configmap_secret_sync_check.sh prod 2>&1 | grep -q "missing-cm"; then
    echo "  ✔ Detected missing ConfigMap reference"
else
    echo "  ✖ Failed to detect missing reference"
    exit 1
fi

# --- 12. Mock for aws_ebs_unencrypted_volumes.sh ---
cat <<'EOF' > "$MOCK_BIN/aws"
#!/bin/bash
if [[ "$*" == *"ec2 describe-volumes"* ]]; then
  echo '[["vol-0123456789abcdef0", 10, "in-use", "prod-data"]]'
fi
EOF
chmod +x "$MOCK_BIN/aws"

echo "Testing aws_ebs_unencrypted_volumes.sh..."
if ./aws_scripts/aws_ebs_unencrypted_volumes.sh 2>&1 | grep -q "vol-0123456789abcdef0"; then
    echo "  ✔ Found unencrypted EBS volume"
else
    echo "  ✖ Failed to find unencrypted volume"
    exit 1
fi

# --- 13. Mock for docker_image_history_audit.sh ---
cat <<'EOF' > "$MOCK_BIN/docker"
#!/bin/bash
if [[ "$*" == *"history"* ]]; then
  echo -e "COPY /app/secret.txt /app/secret.txt\t100MB"
  echo -e "ENV DB_PASS=secret123\t0B"
  echo -e "RUN apt-get update\t200MB"
fi
EOF
chmod +x "$MOCK_BIN/docker"

echo "Testing docker_image_history_audit.sh..."
if ./docker_scripts/docker_image_history_audit.sh my-image 2>&1 | grep -q "DB_PASS"; then
    echo "  ✔ Found sensitive keyword in history"
else
    echo "  ✖ Failed to find sensitive keyword"
    exit 1
fi

# --- 14. Mock for gh_repo_compliance_audit.sh ---
cat <<'EOF' > "$MOCK_BIN/gh"
#!/bin/bash
if [[ "$*" == *"repo view"* ]]; then
  echo '{"isPrivate": false, "deleteBranchOnMerge": false, "defaultBranchRef": {"name": "main"}}'
elif [[ "$*" == *"api"* ]]; then
  echo '{"message": "Not Found"}'
fi
EOF
chmod +x "$MOCK_BIN/gh"

echo "Testing gh_repo_compliance_audit.sh..."
if ./github_scripts/gh_repo_compliance_audit.sh owner/repo 2>&1 | grep -q "Public"; then
    echo "  ✔ Audited repo compliance"
else
    echo "  ✖ Failed compliance audit"
    exit 1
fi

# --- 15. Mock for check_system_entropy.sh ---
# Create a dummy entropy file and mock 'cat' to use it
mkdir -p "$MOCK_BIN/proc/sys/kernel/random"
echo "500" > "$MOCK_BIN/proc/sys/kernel/random/entropy_avail"
echo "4096" > "$MOCK_BIN/proc/sys/kernel/random/poolsize"

cat <<EOF > "$MOCK_BIN/cat"
#!/bin/bash
if [[ "\$*" == "/proc/sys/kernel/random/entropy_avail" ]]; then
  echo "500"
elif [[ "\$*" == "/proc/sys/kernel/random/poolsize" ]]; then
  echo "4096"
else
  /bin/cat "\$@"
fi
EOF
chmod +x "$MOCK_BIN/cat"

# We also need to fool the [ -f ] check if possible, or just skip it if it's hard.
# Actually, the script checks [ -f "$ENTROPY_FILE" ].
# In the sandbox, /proc/sys/kernel/random/entropy_avail MIGHT exist.
# Let's check if it exists first.

echo "Testing check_system_entropy.sh..."
if [ -f "/proc/sys/kernel/random/entropy_avail" ]; then
    # Use real cat but expect the warning if entropy is low, or mock it.
    # Since we can't easily change the real /proc, we rely on the mocked 'cat'
    # but the [ -f ] check still looks at the real file system.
    if ./general_scripts/check_system_entropy.sh 1000 2>&1 | grep -q "Low entropy detected"; then
        echo "  ✔ Detected low entropy (via mocked cat)"
    else
        # If it didn't find "Low entropy", maybe it's because entropy > 1000 on this machine.
        # But our mocked cat returns 500.
        echo "  ✖ Failed to detect low entropy"
        exit 1
    fi
else
    echo "  ⚠ Skipping entropy test (not on Linux or /proc not available)"
fi

echo "All logic verifications passed!"
