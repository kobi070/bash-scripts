# terraform_scripts/templates — authoring guide (SKELETON)

## Scope
Reusable Terraform project templates: complete, copy-ready layouts (modules + environment
root modules) that teams clone as the starting point for new infrastructure repositories.
`TERRAFORM_BEST_PRACTICES.md` in this folder is the **source of truth** — every template
must comply with it in full.

## Naming convention
- Each template lives in `templates/<name>/` (e.g. `generic/`), lowercase snake_case.
- Inside a template: a `modules/` + `live/` split — `modules/<module_name>/` for reusable
  modules, `live/<env>/<stack>/` for environment root modules.
- `snake_case` for all resource names, variables, outputs, locals.
- Resource names describe role, not type (`aws_s3_bucket.artifacts`, never
  `aws_s3_bucket.s3_bucket_artifacts`); use `this` for the single primary resource
  of a type in a module.

## Required tools
terraform (>= 1.10). Templates must pass `terraform fmt -check`, `terraform validate`,
and `terraform test` without cloud credentials (tests use `mock_provider`).

## Required structure
1. **Modules** (`modules/<name>/`) follow the standard file layout:
   `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` (+ optional `locals.tf`,
   `data.tf`), a `README.md`, at least one working example under `examples/`, and
   tests under `tests/*.tftest.hcl` using `mock_provider`.
2. **Root modules** (`live/<env>/<stack>/`) carry `backend.tf` + `providers.tf` —
   `backend` and `provider` blocks **never** go inside reusable modules.
3. **Versions**: reusable modules declare *minimum* provider versions (`>= 5.0`);
   root modules pin with `~>` (pessimistic constraint) and commit `.terraform.lock.hcl`.
4. Every variable has `description` + `type`; every output has `description`.
5. No secrets, account IDs, or regions hardcoded — parameterize via variables/tfvars
   or use placeholder `CHANGE-ME` values clearly marked for replacement.
6. Every template change must pass `terraform fmt -check`, `terraform validate`,
   and `terraform test`.

## Checklist before opening a PR (see AGENTS.md)
- [ ] Test updated: `tests/terraform_scripts/test_templates_generic.sh` (or a new
      `tests/terraform_scripts/test_templates_<name>.sh` for a new template)
- [ ] `terraform_scripts/README.md` updated
- [ ] CHANGELOG entry added
- [ ] No secrets or hardcoded environment-specific values
- [ ] `terraform fmt -check`, `terraform validate`, `terraform test` pass
