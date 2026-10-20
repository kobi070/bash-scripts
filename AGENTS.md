# Instructions for AI Agents

Welcome to the DevOps Automation Repository. This file provides guidelines for maintaining and expanding our collection of scripts and Azure DevOps templates.

## 🛠️ General Principles

- **Modular over Monolithic**: Prefer small, reusable step templates over large, complex ones.
- **Left-Shift Security**: Always integrate security checks (Gitleaks, Trivy, Xray) at the earliest possible stage in your templates.
- **Strict Parameterization**: Avoid hardcoding service connections, organizations, or project-specific values. Use parameters with sensible defaults.
- **Cross-Platform**: When writing shell scripts, ensure they are POSIX-compliant or explicitly handle Bash/PowerShell differences.
- **Idempotency**: Scripts should be safe to run multiple times. Check for existing resources before creating them.

## 📂 Azure DevOps Templates (`az_devops_templates/`)

- **`common/`**: Contains step-level templates.
- **`jobs/`**: Contains job-level templates. Use `parameters` of type `stepList` to allow customization of standardized jobs.
- **`pipelines/`**: Contains full pipeline examples. Use these to showcase how to combine `common` and `jobs`.
- **`pipelines/utils/`**: Utility pipelines for maintenance (cleanup, audits, etc.).

### Trigger Conventions
Azure DevOps does not support `trigger` blocks inside templates. When providing pipeline examples, always include a standard `trigger` block following GitFlow conventions:
```yaml
trigger:
  branches:
    include:
      - main
      - develop
      - feature/*
      - release/*
```

## 📜 Shell Scripts

- Always include a `usage()` function.
- Use `set -euo pipefail` for robustness.
- Explicitly check for required CLI tools (e.g., `command -v jf`).

## 🔀 Git Workflow (GitFlow)

- **Branch flow is strict**: `feature/*` → `develop` → `main`. Never commit or push directly to `main` or `develop`.
- **Everything moves through PRs** — no exceptions. This includes stacked branches: if `feature/b` was branched off `feature/a`, it PRs **back to `feature/a`** (its base), never directly to `develop`/`main`. Unrelated work gets its own `feature/*` branch cut from `develop`.
- **Always confirm with the repository owner before committing and pushing** any changes. Do not auto-commit.
- New work starts from an up-to-date `develop` on a `feature/*` branch; open a PR to `develop`.
- **Quality gates on `feature/*` → `develop` PRs**: bash syntax, ShellCheck, YAML validation, mock-based tests (`tests/`), and secret scanning (Gitleaks). Fix findings before merge.
- Releases: PR `develop` → `main`. A push to `main` triggers the release workflow, which reads the version from the top `## vX.Y.Z` entry in `CHANGELOG.md` and creates the tag + GitHub Release. Bump `CHANGELOG.md` in the release PR.
- **Pre-releases on `develop`**: every push to `develop` tags `vX.Y.Z-rc.N` (prerelease) from the top CHANGELOG entry. The CHANGELOG version on `develop` must always be **one version ahead of `main`'s latest release** — develop is always the next version in progress.
- Hotfixes: `hotfix/*` → `main`, then sync back to `develop`.

## ✅ Verification

Before submitting changes:
1. Run the basic YAML syntax validator: `python3 -c "import yaml; yaml.safe_load(open('file.yml'))"` (if PyYAML is available).
2. For shell scripts, run `bash -n script.sh` to check for syntax errors.
3. Update the relevant `README.md` file.
