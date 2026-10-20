#!/bin/bash
# Tests for general_scripts/auto_completion.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

# Isolate ~/.bashrc writes
export HOME="$MOCK_BIN"
touch "$HOME/.bashrc"

# App with native 'completion bash' support
mock_cmd goodapp <<'EOF'
#!/bin/bash
[[ "$1" == "completion" ]] && echo "complete -F _goodapp goodapp"
EOF

# App with separate completer binary (AWS CLI v2 style)
mock_cmd keyedapp <<'EOF'
#!/bin/bash
exit 1
EOF
mock_cmd keyedapp_completer <<'EOF'
#!/bin/bash
exit 0
EOF

# App with no completion at all
mock_cmd bareapp <<'EOF'
#!/bin/bash
exit 1
EOF

AC=./general_scripts/auto_completion.sh

echo "Testing auto_completion.sh..."

output=$($AC -arg goodapp 2>&1); code=$?
assert_exit_code "$code" 0 "native completion exits 0"
assert_contains "$(cat "$HOME/.bashrc")" "source <(goodapp completion bash)" "bashrc gets source line"

output=$($AC -arg keyedapp 2>&1); code=$?
assert_exit_code "$code" 0 "completer-binary fallback exits 0"
assert_contains "$(cat "$HOME/.bashrc")" "complete -C" "bashrc gets complete -C line"
assert_contains "$(cat "$HOME/.bashrc")" "keyedapp_completer" "complete -C references completer binary"

output=$($AC -arg bareapp 2>&1); code=$?
assert_exit_code "$code" 1 "no completion exits 1"
assert_contains "$output" "No bash completion available" "warns when unsupported"

output=$($AC -arg definitely-missing-cmd 2>&1); code=$?
assert_exit_code "$code" 1 "missing app exits 1"

test_summary
