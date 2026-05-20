# az_scripts

This directory contains scripts for automating **Azure CLI** and **Azure DevOps** operations.

## 📖 Overview
These scripts cover organization configuration, pipeline management, and repository setup.

## 📜 Scripts Overview

1. **az_devops_config.sh**: Configures CLI with Org URL and PAT.
2. **az_devops_run_pipeline.sh / az_devops_wait_pipeline.sh**: Triggers and monitors pipeline runs.
3. **az_devops_list_pipelines.sh**: Lists all pipelines in a project.
4. **az_pipeline_status.sh**: Detailed status of a specific pipeline run.
5. **az_repo_tag_watcher.sh**: Triggers pipelines based on new Git tags.
6. **az_devops_vars_util.sh**: Manages Azure DevOps variable groups.
7. **az_list_repos.sh**: Lists all repositories in a project.
8. **az_script.sh**: Basic project and repo setup.
9. **az_script_advance.sh**: E2E project, repo, and pipeline setup.
10. **az_script_with_user.sh**: Interactive project setup wizard.

## 🚀 Usage

### Configure CLI
```bash
export AZ_DEVOPS_PAT="your_pat"
./az_devops_config.sh https://dev.azure.com/your-org
```

### Run Pipeline
```bash
./az_devops_run_pipeline.sh --name "my-pipeline" --project "my-project"
```

## ✅ Prerequisites

- Azure CLI installed.
- `azure-devops` extension installed (`az extension add --name azure-devops`).
- `jq` installed for JSON processing.

## 📘 Notes
- Most scripts require `AZ_DEVOPS_PAT` to be set in the environment.
