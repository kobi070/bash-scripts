#!/bin/bash
set -euo pipefail

MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
export GITHUB_TOKEN="mock_token"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Mock curl to verify it receives the header via stdin
cat <<'MOCKCURL' > "$MOCK_BIN/curl"
#!/bin/bash
# Check if -K- is used
HAS_K_STDIN=false
for arg in "$@"; do
    if [[ "$arg" == "-K-" ]]; then
        HAS_K_STDIN=true
    fi
done

if [ "$HAS_K_STDIN" = true ]; then
    # Read from stdin to see if it contains the token
    STDIN_CONTENT=$(cat -)
    if echo "$STDIN_CONTENT" | grep -q "Authorization: token mock_token"; then
        # Return a mock JSON response for the scripts to continue
        if [[ "$*" == *"pulls"* ]] && [[ "$*" != *"pulls/1"* ]]; then
            echo '[{"number": 1, "title": "Test PR", "url": "https://api.github.com/repos/owner/repo/pulls/1"}]'
        elif [[ "$*" == *"pulls/1"* ]]; then
             echo '{"additions": 10, "deletions": 5}'
        elif [[ "$*" == *"runs?status=failure"* ]]; then
            echo '{"workflow_runs": [{"id": 123}]}'
        elif [[ "$*" == *"runs/123/jobs"* ]]; then
            echo '{"jobs": [{"id": 456, "name": "test-job", "conclusion": "failure"}]}'
        elif [[ "$*" == *"jobs/456/logs"* ]]; then
            echo "Mock logs content"
        else
            echo "{}"
        fi
    else
        echo "Error: Authorization header not found in stdin" >&2
        kill -s TERM $PPID
    fi
else
    # Check if it was passed as -H (old insecure way)
    if [[ "$*" == *"Authorization: token"* ]]; then
         echo "Error: Insecure Authorization header found in arguments" >&2
         kill -s TERM $PPID
    fi
    echo "Error: curl called without -K-" >&2
    kill -s TERM $PPID
fi
MOCKCURL
chmod +x "$MOCK_BIN/curl"

echo "Verifying gh_pr_size_checker.sh..."
./github_scripts/gh_pr_size_checker.sh owner/repo > /tmp/out 2>&1 || (cat /tmp/out; false)
if grep -q "#1" /tmp/out; then
    echo "  ✔ gh_pr_size_checker.sh passed verification"
else
    echo "  ✖ gh_pr_size_checker.sh failed verification"
    cat /tmp/out
    false
fi

echo "Verifying gh_workflow_failure_logs.sh..."
./github_scripts/gh_workflow_failure_logs.sh owner/repo ci.yml > /tmp/out 2>&1 || (cat /tmp/out; false)
if grep -q "Mock logs content" /tmp/out; then
    echo "  ✔ gh_workflow_failure_logs.sh passed verification"
else
    echo "  ✖ gh_workflow_failure_logs.sh failed verification"
    cat /tmp/out
    false
fi

echo "All curl-based scripts verified!"
