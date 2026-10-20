#!/bin/bash
# Tests for aws_scripts/aws_audit.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

mock_cmd aws <<'EOF'
#!/bin/bash
if [[ "$*" == *"describe-security-groups"* ]]; then
  echo '[{"GroupId":"sg-open","GroupName":"open-sg","IpPermissions":[{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}]}]'
else
  echo '[]'
fi
EOF

echo "Testing aws_audit.sh..."

output=$(./aws_scripts/aws_audit.sh --list 2>&1); code=$?
assert_exit_code "$code" 0 "--list exits 0"
assert_contains "$output" "sg " "--list shows sg type"
assert_contains "$output" "aws_resource_tag_audit.sh" "--list maps tags type"

output=$(./aws_scripts/aws_audit.sh --type sg 2>&1); code=$?
assert_exit_code "$code" 0 "--type sg exits 0"
assert_contains "$output" "sg-open" "sg audit finds open security group"
assert_contains "$output" "Passed:  1" "summary counts pass"

output=$(./aws_scripts/aws_audit.sh --type bogus 2>&1); code=$?
assert_exit_code "$code" 0 "unknown type skipped, exits 0"
assert_contains "$output" "unknown audit type" "warns on unknown type"
assert_contains "$output" "Skipped: 1" "summary counts skip"

output=$(./aws_scripts/aws_audit.sh --days abc 2>&1 || true)
assert_contains "$output" "must be a positive integer" "rejects non-numeric days"

test_summary
