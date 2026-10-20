# Changelog

All notable changes to this repository are documented in this file.

The **top entry's version is the source of truth for releases**: when code is
pushed to `main`, the release workflow parses the first `## vX.Y.Z` heading in
this file, validates it is newer than the latest git tag, and creates the
matching tag and GitHub Release. Legacy `vX,Y` / `vX.Y` formats are normalized
to `vX.Y.0`.

Format inspired by [Keep a Changelog](https://keepachangelog.com/). Versions
follow [Semantic Versioning](https://semver.org/). On `develop`, the top entry
is always the **next** version in progress; each push to `develop` publishes a
`vX.Y.Z-rc.N` prerelease tag.

## v1.3.0 - ArgoCD health tooling (in development)

### Added
- `argocd_scripts/argocd_app_degraded.sh`: checks whether an ArgoCD app (or all apps with `--all`) is Degraded and lists which resources/services are degraded. Flags: `--show-all` (every non-Healthy state), `--warn-only` (always exit 0), `--json`. Exits 1 when unhealthy resources are found, for CI/monitoring gates.
- Test `tests/argocd_scripts/test_argocd_app_degraded.sh` (mocked argocd CLI, 19 assertions).

## v1.2.0 - CI/CD hardening & workflow enforcement (in development)

### Added
- Testing infrastructure: `tests/run_all.sh` runner, `tests/lib/mock.sh` helper, per-script tests (`tests/<folder>/test_<script>.sh`) seeded for aws_resource_inventory, aws_audit, aws_profile_manager, auto_completion; `tests/README.md`.
- Authoring skeletons: `templates/script_skeleton.sh` + `SKELETON.md` in every scripts folder (naming, structure, constraints, PR checklist).
- Azure DevOps GitFlow stage templates (`az_devops_templates/stages/`): `ci_validation_stage.yml`, `release_stage.yml`, `rc_prerelease_stage.yml` — one per GitHub Actions workflow.
- CI README-freshness check: warns when a folder's scripts change without its README.md.
- `.github/workflows/rc-release.yml`: every push to `develop` tags `vX.Y.Z-rc.N` and publishes a GitHub prerelease from the top CHANGELOG entry; validates develop stays one version ahead of main.
- CI quality gates on PRs to `develop`: full test suite (`tests/run_all.sh`) and Gitleaks secret scanning.
- CI branch-flow enforcement for stacked branches: `feature/*` cut from another `feature/*` must PR back to its base.
- `general_scripts/auto_completion.sh`: `<app>_completer` fallback (AWS CLI v2 support).
- `aws_scripts/aws_profile_manager.sh`: manage AWS CLI profiles (add/edit/delete/view/list/switch).

### Changed
- `release.yml`: latest-tag detection now ignores `-rc` prerelease tags.
- `AGENTS.md`: PR-only workflow rules, stacked-branch policy, RC/versioning conventions, mandatory tests/docs/ADO-parity conventions.
- `aws_resource_inventory.sh`: exits non-zero when requested services are unsupported.
- Hardened docker & minikube scripts (`set -euo pipefail`, proper tool checks).

## v1.1.0 - AWS inventory & unified audit, CI/CD release pipeline

### Added
- `aws_scripts/aws_resource_inventory.sh`: inventory all taggable resources via the Resource Groups Tagging API, or selected services (ec2, s3, iam, rds, lambda, vpc, ebs, sg, elb, eks) with native CLI detail. Supports `--region`, `--profile`, `--output table|json`.
- `aws_scripts/aws_audit.sh`: unified dispatcher running one, several, or all existing AWS audit scripts (`--type sg,iam-admin,...|all`) with `--region`/`--days` passthrough and a pass/fail/skip summary.
- `.github/workflows/ci.yml`: PR validation (bash syntax, shellcheck, YAML) and GitFlow branch-flow enforcement (`feature/*` → `develop`, `develop`/`hotfix/*` → `main`).
- `.github/workflows/release.yml`: on push to `main`, reads the version from this file, validates it against the latest tag, and creates the git tag + GitHub Release.
- `CHANGELOG.md` (this file) as the release version source of truth.

### Changed
- `aws_scripts/README.md`: documented the two new scripts and usage examples.

## v1.0.0 - Initial tagged release

- Collection of DevOps automation scripts: AWS, Azure, ArgoCD, Docker, GitHub, JFrog, Kubernetes, Terraform, and general utilities.
- Azure DevOps pipeline templates (`az_devops_templates/`).
