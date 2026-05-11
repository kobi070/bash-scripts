# az_scripts

This directory contains shell scripts for managing **Azure** resources and **Azure DevOps** automation using the Azure CLI.

## 📜 Scripts Overview

### Azure DevOps Automation
1. **az_devops_config.sh**
   Configures the Azure DevOps CLI with Organization URL and Personal Access Token (PAT).

2. **az_devops_vars_util.sh**
   Utility for managing Azure DevOps Variable Groups (list, create, update).

3. **az_devops_run_pipeline.sh / az_devops_wait_pipeline.sh**
   Triggers a pipeline run and waits for its completion.

4. **az_pipeline_status.sh**
   Checks the current status of a specific pipeline run.

5. **az_list_repos.sh**
   Lists all repositories within an Azure DevOps project.

### Resource Management
6. **az_script_advance.sh**
   An end-to-end script that creates a repo, pushes code, and sets up a CI/CD pipeline in Azure DevOps.

7. **az_script_with_user.sh**
   Interactive script for setting up Azure DevOps resources with user prompts.

## 🚀 Usage

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

✅ Prerequisites

- Azure CLI (`az`) installed.
- Azure DevOps extension for Azure CLI (`az extension add --name azure-devops`).
- Valid PAT with sufficient permissions.

📘 Notes
- Use `az login` to authenticate before running resource management scripts.
