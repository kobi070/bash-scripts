#!/bin/bash

# tests/security_validation_bump.sh
# Verifies that bump_version.sh is not vulnerable to command substitution.

set -euo pipefail

# Create a temporary directory for the test
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

VERSION_FILE="$TEST_DIR/version.txt"
PWNED_FILE="$TEST_DIR/pwned.txt"

# Export a function that creates the pwned file
version() {
    touch "$PWNED_FILE"
}
export -f version

new_version() {
    touch "$PWNED_FILE"
}
export -f new_version

# Case 1: Invalid version string
echo "invalid.version" > "$VERSION_FILE"
echo "Running security validation on bump_version.sh (Case 1: Invalid version)..."

# Run the script. It should fail.
# We don't use pipe here to avoid potential issues in the test environment
./general_scripts/bump_version.sh "$VERSION_FILE" patch 2>"$TEST_DIR/error.log" || true
if grep -q "Error: No valid version" "$TEST_DIR/error.log"; then
    echo "[PASS] Script correctly rejected invalid version string."
else
    echo "[FAIL] Script did not reject invalid version string with expected error."
    echo "Actual stderr: $(cat "$TEST_DIR/error.log")"
fi

if [ -f "$PWNED_FILE" ]; then
    echo "[FAIL] SECURITY VULNERABILITY DETECTED: Command substitution triggered for invalid version!"
    rm -f "$PWNED_FILE"
    exit 1
fi

# Case 2: Command named 'version'
echo "1.2.3" > "$VERSION_FILE"
echo "Running security validation on bump_version.sh (Case 2: Command named 'version')..."

./general_scripts/bump_version.sh "$VERSION_FILE" patch > /dev/null

if [ -f "$PWNED_FILE" ]; then
    echo "[FAIL] SECURITY VULNERABILITY DETECTED: Command 'version' was executed!"
    rm -f "$PWNED_FILE"
    exit 1
else
    echo "[PASS] Command 'version' was NOT executed."
fi

# Case 3: Command named 'new_version'
echo "1.2.3" > "$VERSION_FILE"
echo "Running security validation on bump_version.sh (Case 3: Command named 'new_version')..."
./general_scripts/bump_version.sh "$VERSION_FILE" patch > /dev/null

if [ -f "$PWNED_FILE" ]; then
    echo "[FAIL] SECURITY VULNERABILITY DETECTED: Command 'new_version' was executed!"
    rm -f "$PWNED_FILE"
    exit 1
else
    echo "[PASS] Command 'new_version' was NOT executed."
fi

# Final check of functionality
NEW_VERSION=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_FILE" | head -n 1)
if [ "$NEW_VERSION" == "1.2.4" ]; then
    echo "[PASS] Version bumped correctly to 1.2.4"
else
    echo "[FAIL] Version was not bumped correctly: $NEW_VERSION"
    exit 1
fi

echo "All security validations passed!"
exit 0
