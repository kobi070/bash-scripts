# tests

## 📖 Overview
Mock-based test suite for all scripts in this repository. No cloud credentials or
network access needed — external CLIs (`aws`, `kubectl`, `curl`, ...) are mocked.

## 🗂 Layout
```
tests/
├── run_all.sh              # Entry point: legacy harnesses + all per-script tests
├── lib/mock.sh             # Shared helper: mock_cmd, assert_*, test_summary
├── verify_all.sh           # Legacy integration harness (kept green)
├── verify_curl_scripts.sh  # Legacy curl-script harness
└── <scripts_folder>/       # Mirrors a top-level scripts folder
    └── test_<script>.sh    # One test file per script
```

## 🚀 Running
```bash
tests/run_all.sh                                  # everything
bash tests/aws_scripts/test_aws_audit.sh          # single test
```

## ➕ Adding a test (required for every new script)
Create `tests/<folder>/test_<script_name>.sh`:

```bash
#!/bin/bash
set -uo pipefail
cd "$(dirname "$0")/../.."
source tests/lib/mock.sh

mock_cmd aws <<'EOF'
#!/bin/bash
echo '{"mocked": true}'
EOF

output=$(./aws_scripts/my_script.sh 2>&1); code=$?
assert_exit_code "$code" 0 "exits 0"
assert_contains "$output" "expected text" "prints expected output"

test_summary
```

Helpers from `lib/mock.sh`:
- `mock_cmd <name>` — create a mock binary on PATH (body from stdin heredoc)
- `assert_contains / assert_not_contains <output> <needle> [desc]`
- `assert_exit_code <actual> <expected> [desc]`
- `test_summary` — prints result, exits 1 on any failure

`run_all.sh` auto-discovers `tests/*/test_*.sh` — no registration needed.
CI runs the full suite on every PR to `develop` and `main`.
