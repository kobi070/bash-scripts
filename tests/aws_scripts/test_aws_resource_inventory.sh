#!/bin/bash
# Tests for aws_scripts/aws_resource_inventory.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

mock_cmd jq <<'EOF'
#!/bin/bash
exec /usr/bin/jq "$@"
EOF

mock_cmd aws <<'EOF'
#!/bin/bash
if [[ "$*" == *"resourcegroupstaggingapi get-resources"* ]]; then
  echo '["arn:aws:ec2:il-central-1:111:instance/i-abc", "arn:aws:s3:::my-bucket"]'
elif [[ "$*" == *"s3api list-buckets"* ]]; then
  echo "my-bucket  2024-01-01"
fi
EOF

echo "Testing aws_resource_inventory.sh..."

output=$(./aws_scripts/aws_resource_inventory.sh --all 2>&1); code=$?
assert_exit_code "$code" 0 "--all exits 0"
assert_contains "$output" "i-abc" "--all lists EC2 ARN"
assert_contains "$output" "my-bucket" "--all lists S3 ARN"
assert_contains "$output" "Total taggable resources found: 2" "--all totals resources"

output=$(./aws_scripts/aws_resource_inventory.sh --services s3 2>&1); code=$?
assert_exit_code "$code" 0 "--services s3 exits 0"
assert_contains "$output" "S3 Buckets" "--services s3 prints header"

output=$(./aws_scripts/aws_resource_inventory.sh --services nosuch 2>&1); code=$?
assert_exit_code "$code" 1 "unsupported service exits 1"
assert_contains "$output" "unsupported service" "warns on unsupported service"

output=$(./aws_scripts/aws_resource_inventory.sh --output bogus 2>&1 || true)
assert_contains "$output" "--output must be" "rejects invalid output format"

test_summary
