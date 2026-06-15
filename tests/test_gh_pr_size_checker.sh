#!/bin/bash
set -euo pipefail

# test_gh_pr_size_checker.sh - Unit tests for the GitHub PR size checker.
# It uses mocks to simulate various GitHub GraphQL API responses.

MOCK_BIN=$(mktemp -d)
export PATH="$MOCK_BIN:$PATH"
export GITHUB_TOKEN="mock_token"

# Cleanup on exit
trap 'rm -rf "$MOCK_BIN"' EXIT

# Mock curl to return specific GraphQL responses based on the request content
cat <<'MOCKCURL' > "$MOCK_BIN/curl"
#!/bin/bash
STDIN_CONTENT=$(cat -)
# echo "DEBUG MOCK CURL STDIN: $STDIN_CONTENT" >&2

# Detect size category from a mock "request identifier" passed in the repo name for testing
if echo "$STDIN_CONTENT" | grep -q "XS_REPO"; then
    echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 1, "title": "XS PR", "additions": 5, "deletions": 2}]}}}}'
elif echo "$STDIN_CONTENT" | grep -q "S_REPO"; then
    echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 2, "title": "S PR", "additions": 20, "deletions": 10}]}}}}'
elif echo "$STDIN_CONTENT" | grep -q "M_REPO"; then
    echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 3, "title": "M PR", "additions": 60, "deletions": 40}]}}}}'
elif echo "$STDIN_CONTENT" | grep -q "XL_REPO"; then
    echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 5, "title": "XL PR", "additions": 1000, "deletions": 500}]}}}}'
elif echo "$STDIN_CONTENT" | grep -q "L_REPO"; then
    echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 4, "title": "L PR", "additions": 150, "deletions": 150}]}}}}'
elif echo "$STDIN_CONTENT" | grep -q "EMPTY_REPO"; then
    echo '{"data": {"repository": {"pullRequests": {"nodes": []}}}}'
elif echo "$STDIN_CONTENT" | grep -q "ERROR_REPO"; then
    echo '{"errors": [{"message": "Could not resolve to a Repository with the name \"owner/ERROR_REPO\""}]}'
else
    echo '{"data": {"repository": {"pullRequests": {"nodes": [{"number": 99, "title": "Default PR", "additions": 0, "deletions": 0}]}}}}'
fi
MOCKCURL
chmod +x "$MOCK_BIN/curl"

echo "Starting gh_pr_size_checker.sh unit tests..."

# 1. Test XS Category
echo "Testing XS category..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh owner/XS_REPO)
if echo "$OUTPUT" | grep "^#1" | grep -qE "[[:space:]]XS[[:space:]]*$"; then
    echo "  ✔ Passed XS test"
else
    echo "  ✖ Failed XS test"
    echo "$OUTPUT"
    exit 1
fi

# 2. Test S Category
echo "Testing S category..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh owner/S_REPO)
if echo "$OUTPUT" | grep "^#2" | grep -qE "[[:space:]]S[[:space:]]*$"; then
    echo "  ✔ Passed S test"
else
    echo "  ✖ Failed S test"
    echo "$OUTPUT"
    exit 1
fi

# 3. Test M Category
echo "Testing M category..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh owner/M_REPO)
if echo "$OUTPUT" | grep "^#3" | grep -qE "[[:space:]]M[[:space:]]*$"; then
    echo "  ✔ Passed M test"
else
    echo "  ✖ Failed M test"
    echo "$OUTPUT"
    exit 1
fi

# 4. Test L Category
echo "Testing L category..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh owner/L_REPO)
if echo "$OUTPUT" | grep "^#4" | grep -qE "[[:space:]]L[[:space:]]*$"; then
    echo "  ✔ Passed L test"
else
    echo "  ✖ Failed L test"
    echo "$OUTPUT"
    exit 1
fi

# 5. Test XL Category
echo "Testing XL category..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh owner/XL_REPO)
if echo "$OUTPUT" | grep "^#5" | grep -qE "[[:space:]]XL[[:space:]]*$"; then
    echo "  ✔ Passed XL test"
else
    echo "  ✖ Failed XL test"
    echo "$OUTPUT"
    exit 1
fi

# 6. Test Empty Repository
echo "Testing empty repository..."
OUTPUT=$(./github_scripts/gh_pr_size_checker.sh owner/EMPTY_REPO)
if echo "$OUTPUT" | grep -q "No open PRs found"; then
    echo "  ✔ Passed empty repository test"
else
    echo "  ✖ Failed empty repository test"
    echo "$OUTPUT"
    exit 1
fi

# 7. Test API Error
echo "Testing API error handling..."
# Redirect stderr to stdout to capture error messages
OUTPUT=$(GITHUB_TOKEN=mock_token ./github_scripts/gh_pr_size_checker.sh owner/ERROR_REPO 2>&1 || true)
if echo "$OUTPUT" | grep -q "Error: GitHub API returned errors"; then
    echo "  ✔ Passed error handling test"
else
    echo "  ✖ Failed error handling test"
    echo "DEBUG: Output was: $OUTPUT"
    exit 1
fi

echo "All gh_pr_size_checker.sh unit tests passed!"
