# Changelog

All notable changes to this repository are documented in this file.

The **top entry's version is the source of truth for releases**: when code is
pushed to `main`, the release workflow parses the first `## vX.Y.Z` heading in
this file, validates it is newer than the latest git tag, and creates the
matching tag and GitHub Release. Legacy `vX,Y` / `vX.Y` formats are normalized
to `vX.Y.0`.

Format inspired by [Keep a Changelog](https://keepachangelog.com/). Versions
follow [Semantic Versioning](https://semver.org/).

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
