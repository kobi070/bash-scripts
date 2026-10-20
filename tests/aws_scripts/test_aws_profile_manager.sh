#!/bin/bash
# Tests for aws_scripts/aws_profile_manager.sh
# Uses AWS_CONFIG_FILE / AWS_SHARED_CREDENTIALS_FILE overrides for isolation.
set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

# Use the REAL aws CLI with env-isolated config/credentials files
# (aws_profile_manager writes profiles via 'aws configure set').
if ! command -v aws &> /dev/null; then
    echo "SKIP: aws CLI not installed; cannot test aws_profile_manager.sh."
    exit 0
fi

export AWS_CONFIG_FILE="$MOCK_BIN/config"
export AWS_SHARED_CREDENTIALS_FILE="$MOCK_BIN/credentials"
touch "$AWS_CONFIG_FILE" "$AWS_SHARED_CREDENTIALS_FILE"

PM=./aws_scripts/aws_profile_manager.sh

echo "Testing aws_profile_manager.sh..."

output=$($PM add -p testprof --access-key AKIAEXAMPLE --secret-key secret123 --region il-central-1 2>&1); code=$?
assert_exit_code "$code" 0 "add profile exits 0"

output=$($PM list 2>&1)
assert_contains "$output" "testprof" "list shows added profile"

output=$($PM view -p testprof 2>&1)
assert_contains "$output" "il-central-1" "view shows region"
assert_not_contains "$output" "secret123" "view masks secret by default"

output=$($PM add -p testprof --access-key AKIA2 --secret-key s2 2>&1); code=$?
assert_exit_code "$code" 1 "duplicate add without --force fails"

output=$($PM switch -p testprof --env 2>&1)
assert_contains "$output" "export AWS_PROFILE=testprof" "switch --env prints export line"

output=$($PM delete -p testprof --yes 2>&1); code=$?
assert_exit_code "$code" 0 "delete exits 0"
output=$($PM list 2>&1)
assert_not_contains "$output" "testprof" "deleted profile gone from list"

test_summary
