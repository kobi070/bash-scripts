#!/bin/bash
# Test for argocd_scripts/argocd_app_degraded.sh
# Mocks argocd CLI; uses real jq.

set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

SCRIPT=argocd_scripts/argocd_app_degraded.sh

if ! command -v jq &> /dev/null; then
    echo "SKIP: jq not installed."
    exit 0
fi

# Fixtures directory served by the mock
FIXTURES=$(mktemp -d)
trap 'rm -rf "$FIXTURES" "$MOCK_BIN"' EXIT

cat > "$FIXTURES/degraded-app.json" <<'EOF'
{
  "status": {
    "health": {"status": "Degraded"},
    "resources": [
      {"kind": "Deployment", "namespace": "prod", "name": "api", "health": {"status": "Degraded", "message": "crashloop"}},
      {"kind": "Deployment", "namespace": "prod", "name": "web", "health": {"status": "Healthy"}},
      {"kind": "StatefulSet", "namespace": "prod", "name": "db", "health": {"status": "Progressing", "message": "waiting"}}
    ]
  }
}
EOF

cat > "$FIXTURES/healthy-app.json" <<'EOF'
{
  "status": {
    "health": {"status": "Healthy"},
    "resources": [
      {"kind": "Deployment", "namespace": "prod", "name": "api", "health": {"status": "Healthy"}}
    ]
  }
}
EOF

export FIXTURES

mock_cmd argocd <<'EOF'
#!/bin/bash
case "$1 $2" in
    "account get-user-info") exit 0 ;;
    "app get")
        case "$3" in
            degraded-app) cat "$FIXTURES/degraded-app.json" ;;
            healthy-app)  cat "$FIXTURES/healthy-app.json" ;;
            *) echo "app not found"; exit 1 ;;
        esac
        ;;
    "app list")
        printf 'degraded-app\nhealthy-app\n'
        ;;
    *) exit 1 ;;
esac
EOF

echo "== argocd_app_degraded.sh =="

# 1. Degraded app: finds degraded resource, exits 1
output=$(bash "$SCRIPT" degraded-app 2>&1); code=$?
assert_exit_code "$code" 1 "degraded app exits 1"
assert_contains "$output" "api" "lists degraded resource 'api'"
assert_contains "$output" "crashloop" "shows degraded message"
assert_not_contains "$output" "Progressing" "default mode hides Progressing"
assert_not_contains "$output" "web" "healthy resource not listed"

# 2. Healthy app: exits 0
output=$(bash "$SCRIPT" healthy-app 2>&1); code=$?
assert_exit_code "$code" 0 "healthy app exits 0"
assert_contains "$output" "OK:" "prints OK for healthy app"

# 3. --show-all includes Progressing
output=$(bash "$SCRIPT" degraded-app --show-all 2>&1); code=$?
assert_exit_code "$code" 1 "--show-all unhealthy exits 1"
assert_contains "$output" "Progressing" "--show-all includes Progressing resource"
assert_contains "$output" "db" "--show-all lists 'db'"

# 4. --warn-only forces exit 0
output=$(bash "$SCRIPT" degraded-app --warn-only 2>&1); code=$?
assert_exit_code "$code" 0 "--warn-only exits 0"
assert_contains "$output" "Warning" "--warn-only prints warning"

# 5. --json output is valid JSON with expected fields
output=$(bash "$SCRIPT" degraded-app --json 2>/dev/null); code=$?
assert_exit_code "$code" 1 "--json degraded exits 1"
parsed=$(echo "$output" | jq -r '.[0].degraded[0].name' 2>/dev/null)
assert_contains "$parsed" "api" "--json contains degraded resource name"
app_health=$(echo "$output" | jq -r '.[0].appHealth' 2>/dev/null)
assert_contains "$app_health" "Degraded" "--json contains appHealth"

# 6. --all iterates all apps
output=$(bash "$SCRIPT" --all --json 2>/dev/null); code=$?
assert_exit_code "$code" 1 "--all with a degraded app exits 1"
count=$(echo "$output" | jq 'length' 2>/dev/null)
assert_contains "$count" "2" "--all checks both apps"

# 7. Usage errors
output=$(bash "$SCRIPT" 2>&1); code=$?
assert_exit_code "$code" 2 "no args exits 2"
output=$(bash "$SCRIPT" app1 --all 2>&1); code=$?
assert_exit_code "$code" 2 "app name + --all exits 2"

test_summary
