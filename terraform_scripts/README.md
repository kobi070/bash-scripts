# terraform_scripts

## 📖 Overview
This directory contains scripts for setting up and managing **Terraform** environments, ensuring code quality through validation and formatting checks.

## 📜 Scripts Overview

1. **envsetup.sh**  
   Installs Terraform and its dependencies (like `tfenv` or specific CLI versions).

2. **tr_init.sh**  
   Validates that the environment is ready for Terraform operations.

3. **tf_validate_all.sh**
   Recursively searches for Terraform modules and runs `terraform validate` in each.

4. **tf_check_fmt.sh**
   Checks if all Terraform files in the project are properly formatted.

## 🚀 Usage examples

### Setup Environment
```bash
./envsetup.sh
```

### Validate Modules
```bash
./tf_validate_all.sh
```

### Check Formatting
```bash
./tf_check_fmt.sh
```

## 📐 Templates

The `templates/` directory contains authoring guidance and a reusable Terraform project template:

1. **TERRAFORM_BEST_PRACTICES.md**  
   Best-practices document (AI context / source of truth). **Follow it for ALL Terraform code in this repository.**

2. **SKELETON.md**  
   Authoring guide for creating new Terraform templates (naming, structure, constraints).

3. **generic/**  
   Reusable Terraform project template:

   ```text
   generic/
   ├── modules/
   │   ├── s3_bucket/    # Working secure-S3 example module (versioning, SSE, public-access block, TLS-only policy, tftest suite)
   │   └── _template/    # Blank TODO-guided starter module
   └── live/
       ├── dev/example-stack/       # Root modules per environment
       ├── staging/example-stack/   # (placeholder S3 backend, provider default_tags, env tfvars)
       └── prod/example-stack/
   ```

   See `templates/generic/README.md` for usage instructions.

## ✅ Prerequisites

- Terraform CLI installed.
- Python 3 (if using auxiliary Python tools).
- Always run `tf_check_fmt.sh` before committing changes to ensure code quality.
