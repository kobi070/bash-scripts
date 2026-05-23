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

5. **tf_provider_version_check.sh**
   Detects unpinned provider versions in Terraform files.

## 🚀 Usage

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

### Check Provider Versions
```bash
./tf_provider_version_check.sh [path]
```

## ✅ Prerequisites

- Terraform CLI installed.
- Python 3 (if using auxiliary Python tools).

## 📘 Notes
- Always run `tf_check_fmt.sh` before committing changes to ensure code quality.
