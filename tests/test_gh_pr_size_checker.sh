#!/bin/bash
set -euo pipefail

# test_gh_pr_size_checker.sh - Unit tests for gh_pr_size_checker.sh

MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
export GITHUB_TOKEN="mock_token"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Mock curl to simulate GitHub GraphQL responses
cat <<'MOCKCURL' > "$MOCK_BIN/curl"
#!/bin/bash
# Mock curl needs to handle reading from stdin even if it doesn't use it for all cases
# to avoid 'broken pipe' or similar issues if the script uses printf | curl -K-
STDIN_CONTENT=$(cat -)

if [[ "$*" == *"graphql"* ]]; then
    if echo "$STDIN_CONTENT" | grep -q "XS_TEST"; then
        echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 1, "title": "XS PR", "additions": 5, "deletions": 4}]}}}}'
    elif echo "$STDIN_CONTENT" | grep -q "XL_TEST"; then
        echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 5, "title": "XL PR", "additions": 300, "deletions": 300}]}}}}'
    elif echo "$STDIN_CONTENT" | grep -q "L_TEST"; then
        echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 4, "title": "L PR", "additions": 100, "deletions": 150}]}}}}'
    elif echo "$STDIN_CONTENT" | grep -q "M_TEST"; then
        echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 3, "title": "M PR", "additions": 30, "deletions": 30}]}}}}'
    elif echo "$STDIN_CONTENT" | grep -q "S_TEST"; then
        echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 2, "title": "S PR", "additions": 10, "deletions": 10}]}}}}'
    elif echo "$STDIN_CONTENT" | grep -q "EMPTY_TEST"; then
        echo '{"data": {"repository": {"pullRequests": {"nodes": []}}}}'
    elif echo "$STDIN_CONTENT" | grep -q "ERROR_TEST"; then
        echo '{"errors": [{"message": "Could not resolve to a Repository with the name \"owner/non-existent\"."}]}'
    else
        echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 100, "title": "Default PR", "additions": 1, "deletions": 1}]}}}}'
    fi
else
    echo "{}"
fi
MOCKCURL
chmod +x "$MOCK_BIN/curl"

echo "Running tests for gh_pr_size_checker.sh..."

# Test Case 1: XS Size (< 10)
echo "Test Case 1: XS Size..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh XS_TEST/repo 2>&1)
if echo "$OUTPUT" | grep -q "XS" && echo "$OUTPUT" | grep -q "9"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

# Test Case 2: S Size (>= 10)
echo "Test Case 2: S Size..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh S_TEST/repo 2>&1)
if echo "$OUTPUT" | grep -q " S " && echo "$OUTPUT" | grep -q "20"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

# Test Case 3: M Size (>= 50)
echo "Test Case 3: M Size..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh M_TEST/repo 2>&1)
if echo "$OUTPUT" | grep -q " M " && echo "$OUTPUT" | grep -q "60"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

# Test Case 4: L Size (>= 200)
echo "Test Case 4: L Size..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh L_TEST/repo 2>&1)
if echo "$OUTPUT" | grep -q " L " && echo "$OUTPUT" | grep -q "250"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

# Test Case 5: XL Size (>= 500)
echo "Test Case 5: XL Size..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh XL_TEST/repo 2>&1)
if echo "$OUTPUT" | grep -q "XL" && echo "$OUTPUT" | grep -q "600"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

# Test Case 6: No PRs
echo "Test Case 6: No PRs..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh EMPTY_TEST/repo 2>&1)
if echo "$OUTPUT" | grep -q "No open PRs found"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

# Test Case 7: API Error
echo "Test Case 7: API Error..."
# We need to make sure GITHUB_TOKEN is exported for the subshell
export GITHUB_TOKEN="mock_token"
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh ERROR_TEST/repo 2>&1 || true)
if echo "$OUTPUT" | grep -q "Error from GitHub GraphQL API"; then
    echo "  ✔ Passed"
else
    echo "  ✖ Failed"
    echo "$OUTPUT"
    exit 1
fi

echo "All tests passed for gh_pr_size_checker.sh!"
