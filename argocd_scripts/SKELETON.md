# argocd_scripts — authoring guide (SKELETON)

## Scope
ArgoCD operations: app sync/diff/list, installation.

## Naming convention
- Prefix: `argocd_`
- Pattern: `<prefix><action>_<subject>.sh`, lowercase snake_case, action verbs first.

## Required tools
argocd (and kubectl where relevant). Check each with `command -v` before doing any work.

## Required structure (start from `templates/script_skeleton.sh`)
1. `#!/bin/bash` shebang.
2. Header comment block: one-line description, longer description, `Usage:` line, `Example:` line.
3. `set -euo pipefail`.
4. `usage()` function (prints options + exits 1); handle `-h|--help`.
5. Tool checks (`command -v`).
6. Argument parsing with validation; no hardcoded org/project/account values — parameterize with sensible defaults.
7. Main logic: small single-purpose functions, every expansion quoted, prefer one CLI call + `jq` pipeline over per-item CLI loops.
8. Non-zero exit on failure; read-only scripts must never mutate; destructive actions need a confirmation flag (`--yes`) and should be idempotent.

## Checklist before opening a PR (see AGENTS.md)
- [ ] Test added: `tests/argocd_scripts/test_<script>.sh` (see `tests/README.md`)
- [ ] `argocd_scripts/README.md` updated: numbered script entry + usage example
- [ ] `bash -n` and `tests/run_all.sh` pass
- [ ] No secrets or hardcoded environment-specific values
