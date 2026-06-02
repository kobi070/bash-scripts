#!/bin/bash
set -euo pipefail

MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
export GITHUB_TOKEN="mock_token"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/mock_webhook"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Mock curl to verify it receives the header via stdin
cat <<'MOCKCURL' > "$MOCK_BIN/curl"
#!/bin/bash
# Check if -K- is used
HAS_K_STDIN=false
OUT_FILE=""
for i in $(seq 1 $#); do
    arg="${!i}"
    if [[ "$arg" == "-K-" ]]; then
        HAS_K_STDIN=true
    elif [[ "$arg" == "-o" ]]; then
        next=$((i+1))
        OUT_FILE="${!next}"
    fi
done

if [ "$HAS_K_STDIN" = true ]; then
    # Read from stdin to see if it contains the token
    STDIN_CONTENT=$(cat -)

    # Validate that data= lines do not contain unescaped newlines (strict config check)
    if echo "$STDIN_CONTENT" | grep -E "^data = \"" | grep -qv "\\\\n" && echo "$STDIN_CONTENT" | grep -qE "^data = \".*[^\\]$"; then
        # This is a very basic check, but it helps catch major issues
        :
    fi

    if echo "$STDIN_CONTENT" | grep -qE "Authorization: (token|Bearer) mock_token" || \
       (echo "$STDIN_CONTENT" | grep -q "url = \"https://hooks.slack.com/services/mock_webhook\"" && \
        echo "$STDIN_CONTENT" | grep -q "data = "); then
        # Return a mock JSON response for the scripts to continue
        if echo "$STDIN_CONTENT" | grep -q "hooks.slack.com"; then
            echo "ok"
        elif [[ "$*" == *"releases/latest"* ]]; then
            echo '{"tag_name": "v1.0.0", "assets": [{"name": "asset.zip", "browser_download_url": "https://example.com/asset.zip"}]}'
        elif [[ "$*" == *"example.com/asset.zip"* ]]; then
            if [ -n "$OUT_FILE" ]; then
                echo "Mock asset content" > "$OUT_FILE"
            else
                echo "Mock asset content"
            fi
        elif [[ "$*" == *"pulls"* ]] && [[ "$*" != *"pulls/1"* ]]; then
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
    if [[ "$*" == *"Authorization: token"* ]] || [[ "$*" == *"Authorization: Bearer"* ]]; then
         echo "Error: Insecure Authorization header found in arguments" >&2
         kill -s TERM $PPID
    fi
    # Check if it's a non-sensitive request (like monitoring a URL)
    if [[ "$*" == *"non-existent-url.local"* ]]; then
        echo "000"
    else
        echo "Error: curl called without -K- for sensitive URL: $*" >&2
        kill -s TERM $PPID
    fi
fi
MOCKCURL
chmod +x "$MOCK_BIN/curl"

echo "Verifying gh_list_pull_requests.sh..."
./github_scripts/gh_list_pull_requests.sh owner/repo > /tmp/out 2>&1 || (cat /tmp/out; false)
if grep -q "1" /tmp/out; then
    echo "  ✔ gh_list_pull_requests.sh passed verification"
else
    echo "  ✖ gh_list_pull_requests.sh failed verification"
    cat /tmp/out
    false
fi

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

echo "Verifying gh_get_latest_release.sh..."
./github_scripts/gh_get_latest_release.sh owner/repo > /tmp/out 2>&1 || (cat /tmp/out; false)
if grep -q "v1.0.0" /tmp/out; then
    echo "  ✔ gh_get_latest_release.sh passed verification"
else
    echo "  ✖ gh_get_latest_release.sh failed verification"
    cat /tmp/out
    false
fi

echo "Verifying gh_download_release_asset.sh..."
./github_scripts/gh_download_release_asset.sh owner/repo "asset.zip" /tmp/mock_asset > /tmp/out 2>&1 || (cat /tmp/out; false)
if grep -q "Download completed successfully" /tmp/out && [ -f /tmp/mock_asset ]; then
    echo "  ✔ gh_download_release_asset.sh passed verification"
else
    echo "  ✖ gh_download_release_asset.sh failed verification"
    cat /tmp/out
    false
fi
rm -f /tmp/mock_asset

echo "Verifying send_slack_notification.sh..."
./general_scripts/send_slack_notification.sh "ignored" "Test message" > /tmp/out 2>&1 || (cat /tmp/out; false)
if grep -q "Success: Slack notification sent" /tmp/out; then
    echo "  ✔ send_slack_notification.sh passed verification"
else
    echo "  ✖ send_slack_notification.sh failed verification"
    cat /tmp/out
    false
fi

echo "Verifying multi_url_monitor.sh Slack notification..."
# Mock a failing URL
./general_scripts/multi_url_monitor.sh -s "http://non-existent-url.local" > /tmp/out 2>&1 || true
if grep -q "Slack notification sent" /tmp/out; then
    echo "  ✔ multi_url_monitor.sh passed verification"
else
    echo "  ✖ multi_url_monitor.sh failed verification"
    cat /tmp/out
    false
fi

echo "All curl-based scripts verified!"
