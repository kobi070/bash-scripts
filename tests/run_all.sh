#!/bin/bash
# Runs the full test suite:
#   1. Legacy integration harnesses (verify_all.sh, verify_curl_scripts.sh)
#   2. All per-script tests (tests/<folder>/test_*.sh)
# Run from anywhere; paths resolve relative to the repo root.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TESTS_DIR")"
cd "$REPO_ROOT"

FAILED=()
TOTAL=0

run() {
    local label="$1" cmd="$2"
    TOTAL=$((TOTAL + 1))
    echo ""
    echo "===================================================================================================="
    echo ">>> $label"
    echo "===================================================================================================="
    if bash "$cmd"; then
        echo "--- PASS: $label"
    else
        echo "--- FAIL: $label"
        FAILED+=("$label")
    fi
}

# 1. Legacy harnesses
run "legacy: verify_all.sh" "tests/verify_all.sh"
run "legacy: verify_curl_scripts.sh" "tests/verify_curl_scripts.sh"

# 2. Per-script tests
while IFS= read -r -d '' t; do
    run "per-script: ${t#tests/}" "$t"
done < <(find tests -mindepth 2 -name 'test_*.sh' -type f -not -path 'tests/lib/*' -print0 | sort -z)

echo ""
echo "===================================================================================================="
echo "TEST SUITE SUMMARY: $((TOTAL - ${#FAILED[@]}))/$TOTAL passed"
if [[ ${#FAILED[@]} -gt 0 ]]; then
    printf 'FAILED: %s\n' "${FAILED[@]}"
    exit 1
fi
echo "All tests passed."
