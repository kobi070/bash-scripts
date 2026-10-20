# az_devops_templates/stages

## 📖 Overview
Stage-level templates mirroring this repository's GitHub Actions workflows, so the
same GitFlow CI/CD can run on Azure DevOps. One template per workflow:

| GitHub Actions workflow | Azure DevOps stage template | Purpose |
|---|---|---|
| `.github/workflows/ci.yml` | `ci_validation_stage.yml` | Bash syntax, ShellCheck, YAML validation, mock test suite, Gitleaks |
| `.github/workflows/release.yml` | `release_stage.yml` | Parse top `## vX.Y.Z` from CHANGELOG.md, validate > latest stable tag, create release tag (main) |
| `.github/workflows/rc-release.yml` | `rc_prerelease_stage.yml` | Validate develop is ahead of main, create `vX.Y.Z-rc.N` prerelease tag (develop) |

## 🚀 Usage
Templates contain **no triggers** (Azure DevOps does not support `trigger` in
templates). Include them from a pipeline:

```yaml
trigger:
  branches:
    include:
      - main
      - develop
      - feature/*
      - release/*

stages:
  - template: az_devops_templates/stages/ci_validation_stage.yml
    parameters:
      runTests: true
      enableGitleaks: true

  - ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/develop') }}:
    - template: az_devops_templates/stages/rc_prerelease_stage.yml

  - ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/main') }}:
    - template: az_devops_templates/stages/release_stage.yml
```

## 🔑 Requirements
- `release_stage.yml` / `rc_prerelease_stage.yml` push git tags: grant the build
  service identity **Contribute** and **Create tag** on the repository, and keep
  `persistCredentials: true` on checkout.
- Azure DevOps has no native "GitHub Release" — the stage creates the git tag;
  publish artifacts/release notes with an additional step if needed.

## 📜 Conventions
Per `AGENTS.md`: every new GitHub Actions workflow added to this repository must
get a matching stage template here.
