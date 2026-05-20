# terraform_scripts

This directory contains scripts for setting up and managing **Terraform** environments.

## 📖 Overview
These scripts ensure code quality through validation and formatting checks.

## 📜 Scripts Overview

1. **envsetup.sh**: Installs Terraform and its dependencies (like `tfenv`).
2. **tr_init.sh**: Validates that the environment is ready for Terraform operations.
3. **tf_validate_all.sh**: Recursively searches for Terraform modules and runs `terraform validate`.
4. **tf_check_fmt.sh**: Checks if all Terraform files are properly formatted.

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

## ✅ Prerequisites

- Terraform CLI installed.
- `bash` shell.

## 📘 Notes
- Always run `tf_check_fmt.sh` before committing changes to ensure code consistency.
