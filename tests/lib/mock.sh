#!/bin/bash
# Shared mock helper for per-script tests.
# Source this file, then register mocks with mock_cmd.
#
# Usage in a test:
#   source "$(dirname "$0")/../lib/mock.sh"
#   mock_cmd aws <<'EOF'
#   #!/bin/bash
#   echo '{"mocked": true}'
#   EOF
#   assert_contains "$output" "expected" "description"
#   test_summary

MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
trap 'rm -rf "$MOCK_BIN"' EXIT

_FAILURES=0
_ASSERTIONS=0

# mock_cmd <name>  — reads the mock script body from stdin
mock_cmd() {
    local name="$1"
    cat > "$MOCK_BIN/$name"
    chmod +x "$MOCK_BIN/$name"
}

assert_contains() {
    local haystack="$1" needle="$2" desc="${3:-contains '$2'}"
    _ASSERTIONS=$((_ASSERTIONS + 1))
    if echo "$haystack" | grep -qF -- "$needle"; then
        echo "  ✔ $desc"
    else
        echo "  ✖ $desc"
        echo "    expected to find: $needle"
        echo "    in output:"
        echo "$haystack" | sed 's/^/      /'
        _FAILURES=$((_FAILURES + 1))
    fi
}

assert_not_contains() {
    local haystack="$1" needle="$2" desc="${3:-does not contain '$2'}"
    _ASSERTIONS=$((_ASSERTIONS + 1))
    if echo "$haystack" | grep -qF -- "$needle"; then
        echo "  ✖ $desc (found: $needle)"
        _FAILURES=$((_FAILURES + 1))
    else
        echo "  ✔ $desc"
    fi
}

assert_exit_code() {
    local actual="$1" expected="$2" desc="${3:-exit code is $2}"
    _ASSERTIONS=$((_ASSERTIONS + 1))
    if [[ "$actual" -eq "$expected" ]]; then
        echo "  ✔ $desc"
    else
        echo "  ✖ $desc (got $actual, expected $expected)"
        _FAILURES=$((_FAILURES + 1))
    fi
}

test_summary() {
    echo ""
    if [[ "$_FAILURES" -gt 0 ]]; then
        echo "FAILED: $_FAILURES of $_ASSERTIONS assertions failed."
        exit 1
    fi
    echo "PASSED: all $_ASSERTIONS assertions."
}
