# generic — Terraform project template

A copy-ready Terraform project layout: reusable modules + per-environment root modules,
following [`../TERRAFORM_BEST_PRACTICES.md`](../TERRAFORM_BEST_PRACTICES.md) (the source
of truth for every convention used here).

## What it contains

```
generic/
├── modules/
│   ├── _template/              # blank, TODO-guided starter for new modules
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── README.md
│   │   ├── examples/
│   │   └── tests/
│   └── s3_bucket/              # working example: secure-by-default S3 bucket
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── README.md
│       ├── examples/basic/
│       └── tests/*.tftest.hcl  # mock_provider tests — no cloud creds needed
└── live/
    ├── dev/
    │   └── example-stack/      # root module: one state per env per stack
    │       ├── main.tf
    │       ├── backend.tf      # placeholder S3 backend (use_lockfile)
    │       ├── providers.tf    # provider config + default_tags
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── versions.tf
    │       ├── locals.tf
    │       └── terraform.tfvars
    ├── staging/
    │   └── example-stack/
    └── prod/
        └── example-stack/
```

- **`modules/`** — reusable modules. No `backend` or `provider` blocks; minimum
  provider version constraints (`>= 5.0`); each has a README, an example, and
  `terraform test` coverage.
- **`live/`** — environment root modules. One state per environment per stack;
  `~>` provider pins; `backend.tf` + `providers.tf` live only here.

## Quick start

1. **Copy the template** into your infrastructure repo:
   ```bash
   cp -r generic/ /path/to/your-repo/terraform/
   ```
2. **Rename `example-stack`** in each `live/<env>/` directory to your actual stack
   name (e.g. `network`, `data`, `app`).
3. **Configure the backend** — replace the `CHANGE-ME` values in each
   `backend.tf` (bucket, key, region), **or** keep the code generic and supply them
   at init time with partial configuration:
   ```bash
   terraform init -backend-config=backend-dev.hcl
   ```
4. **Add new modules** by copying the starter:
   ```bash
   cp -r modules/_template modules/<your_module_name>
   ```
   Then follow the TODO comments inside.

## How to run

Run Terraform **per stack directory** — each `live/<env>/<stack>/` is its own state:

```bash
cd live/dev/example-stack
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

> **Never apply to shared environments (staging/prod) from a laptop.** All applies to
> shared environments go through the CI/CD pipeline: `fmt -check` → `validate` → lint/scan
> → `plan -out=tfplan` → manual approval → `apply tfplan` (the exact saved plan).

## How to test modules

Modules ship with native `terraform test` suites (`tests/*.tftest.hcl`) that use
`mock_provider`, so **no cloud credentials are needed**:

```bash
cd modules/s3_bucket
terraform init
terraform test
```

Add tests the same way when creating new modules from `modules/_template`.

## Conventions

See [`../TERRAFORM_BEST_PRACTICES.md`](../TERRAFORM_BEST_PRACTICES.md) for the full
ruleset: structure, naming, versioning/pinning, state, security, tagging, testing,
and CI/CD workflow. Every change to this template must comply.
