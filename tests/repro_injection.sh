#!/bin/bash
# repro_injection.sh - Reproduce command injection via indirect expansion

SENTINEL_FILE="pwned_validate_repro"
rm -f "$SENTINEL_FILE"

echo "Attempting to exploit indirect expansion in validate_env_vars.sh..."
# The payload is in the variable name itself
./general_scripts/validate_env_vars.sh "foo[\$(touch $SENTINEL_FILE)]" > /dev/null 2>&1 || true

if [ -f "$SENTINEL_FILE" ]; then
    echo "❌ VULNERABILITY REPRODUCED: $SENTINEL_FILE was created!"
    rm "$SENTINEL_FILE"
    exit 1
else
    echo "✅ Vulnerability not triggered."
    exit 0
fi
