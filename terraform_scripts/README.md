# terraform_scripts

This repository contains scripts and configuration files to help set up and manage Terraform environments efficiently. It includes environment setup, initialization, and dependency management.

## 📜 Files Overview

1. **envsetup.sh**  
   Prepares the environment for Terraform usage. This may include setting environment variables, configuring backends, or installing required tools.

2. **tr_init.sh**  
   Initializes a Terraform working directory. This script typically runs `terraform init` and may include additional setup steps.

3. **requirements.txt**  
   Lists Python dependencies (if any) required for auxiliary scripts or tooling related to Terraform.

## 🚀 Usage

To set up and initialize your Terraform environment, run the following commands:

```bash
./envsetup.sh
./tr_init.sh
```

✅ Prerequisites

- Terraform must be installed and available in your system's PATH.
- Bash shell must be available.
- Python and pip should be installed if using requirements.txt.
📘 Notes
- Always review and customize the scripts to match your infrastructure and backend configuration.
- For more information on Terraform, visit the official Terraform documentation.
