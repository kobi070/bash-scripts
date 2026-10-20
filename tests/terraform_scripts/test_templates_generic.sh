#!/bin/bash
# Test for terraform_scripts/templates/generic/
# Uses the real terraform binary (no mocks): fmt, init/validate, module tests,
# plus static guardrails (no provider/backend blocks in modules, no AWS keys).

set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

if ! command -v terraform &> /dev/null; then
    echo "SKIP: terraform not installed."
    exit 0
fi

GENERIC=terraform_scripts/templates/generic

# Remove init artifacts so the working tree stays clean.
cleanup_tf_artifacts() {
    find "$GENERIC" -type d -name '.terraform' -prune -exec rm -rf {} + 2>/dev/null
    find "$GENERIC" -type f -name '.terraform.lock.hcl' -delete 2>/dev/null
}
trap 'cleanup_tf_artifacts; rm -rf "$MOCK_BIN"' EXIT

# --- 1. Formatting ---
output=$(terraform fmt -check -recursive "$GENERIC" 2>&1); code=$?
assert_exit_code "$code" 0 "terraform fmt -check passes"
[[ "$code" -ne 0 ]] && echo "$output" | sed 's/^/      /'

# --- 2. init + validate every module and live root ---
DIRS=(
    "$GENERIC/modules/s3_bucket"
    "$GENERIC/modules/_template"
    "$GENERIC/live/dev/example-stack"
    "$GENERIC/live/staging/example-stack"
    "$GENERIC/live/prod/example-stack"
)

for dir in "${DIRS[@]}"; do
    output=$(terraform -chdir="$dir" init -backend=false -input=false 2>&1); code=$?
    assert_exit_code "$code" 0 "init succeeds: $dir"
    [[ "$code" -ne 0 ]] && echo "$output" | sed 's/^/      /'

    output=$(terraform -chdir="$dir" validate 2>&1); code=$?
    assert_exit_code "$code" 0 "validate succeeds: $dir"
    [[ "$code" -ne 0 ]] && echo "$output" | sed 's/^/      /'
done

# --- 3. Module test suite (mock_provider based, no credentials needed) ---
output=$(terraform -chdir="$GENERIC/modules/s3_bucket" test 2>&1); code=$?
assert_exit_code "$code" 0 "terraform test passes for s3_bucket module"
assert_contains "$output" "Success!" "test run reports success"
assert_contains "$output" "0 failed" "no failed test runs"
[[ "$code" -ne 0 ]] && echo "$output" | sed 's/^/      /'

# --- 4. Static guardrails ---
# Modules must not declare provider or backend blocks (comments allowed;
# examples/ are root-like configs and may declare providers).
hits=$(grep -rnE '^[[:space:]]*(provider|backend)[[:space:]]+"' "$GENERIC/modules" \
    --include='*.tf' --exclude-dir=examples 2>/dev/null)
assert_exit_code "$([[ -z "$hits" ]] && echo 0 || echo 1)" 0 \
    "no provider/backend blocks in generic modules"
[[ -n "$hits" ]] && echo "$hits" | sed 's/^/      /'

# No AWS access keys anywhere under templates/.
keys=$(grep -rnE 'AKIA[0-9A-Z]{16}' terraform_scripts/templates 2>/dev/null)
assert_exit_code "$([[ -z "$keys" ]] && echo 0 || echo 1)" 0 \
    "no AWS access key IDs under templates/"
[[ -n "$keys" ]] && echo "$keys" | sed 's/^/      /'

test_summary
