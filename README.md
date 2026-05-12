# DevOps Automation Scripts & Templates

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-DevOps-0078D4?logo=azure-devops&logoColor=white)

A comprehensive collection of specialized DevOps scripts and Azure DevOps YAML templates designed to automate installations, configurations, and CI/CD workflows across various environments.

## 🚀 Key Features

- **Modularity**: Small, single-purpose scripts and templates that can be easily composed.
- **Security-First (Sentinel)**: Integrated secret scanning, vulnerability checks, and best practices for credential handling.
- **Cloud Native**: Native support for AWS, Azure, Docker, and Kubernetes.
- **CI/CD Ready**: Reusable Azure DevOps templates and GitHub API automation.
- **Standardized**: Consistent usage patterns, help functions, and error handling across all scripts.

## 📂 Repository Structure

The repository is organized into technology-specific directories:

- [argocd_scripts/](./argocd_scripts/): ArgoCD installation and app management.
- [aws_scripts/](./aws_scripts/): AWS CLI and S3 automation.
- [az_devops_templates/](./az_devops_templates/): Reusable YAML templates for Azure DevOps pipelines.
- [az_scripts/](./az_scripts/): Azure CLI and Azure DevOps automation.
- [docker_scripts/](./docker_scripts/): Docker environment management and security.
- [general_scripts/](./general_scripts/): System utilities, versioning, and monitoring.
- [github_scripts/](./github_scripts/): GitHub API and Git workflow automation.
- [jfrog_scripts/](./jfrog_scripts/): JFrog CLI and Artifactory management.
- [k8s_scripts/](./k8s_scripts/): Kubernetes cluster initialization and resource management.
- [terraform_scripts/](./terraform_scripts/): Terraform environment setup and validation.

## 🛠️ Prerequisites

Most scripts require specific CLI tools. Ensure you have the relevant ones installed:

| Tool | Purpose |
|------|---------|
| **Bash** | Core execution environment (uses `set -euo pipefail`). |
| **jq** | Essential for JSON parsing across almost all scripts. |
| **Docker** | For `docker_scripts`, Trivy scans, and Hadolint. |
| **kubectl** | For `k8s_scripts` and `argocd_scripts`. |
| **Azure CLI** | For `az_scripts` (requires `azure-devops` extension). |
| **AWS CLI** | For `aws_scripts`. |
| **JFrog CLI** | For `jfrog_scripts`. |
| **Terraform** | For `terraform_scripts`. |

## ⚡ Quick Start

1. **Clone the repo**:
   ```bash
   git clone https://github.com/your-repo/devops-automation.git
   cd devops-automation
   ```

2. **Run a system check**:
   ```bash
   ./general_scripts/check_sys_info.sh
   ```

3. **Check Kubernetes resources**:
   ```bash
   ./k8s_scripts/k8s_node_resource_usage.sh
   ```

4. **Scan a Docker image**:
   ```bash
   ./docker_scripts/trivyScans.sh my-image:latest
   ```

## 📜 Available Scripts

### Kubernetes Scripts
- `init_k8s.sh`: Kubernetes initialization and health check.
- `minikube_install.sh`: Automated Minikube installation.
- `k8s_wait_ready.sh`: Waits for resources to reach a ready state.
- `k8s_node_resource_usage.sh`: Summarizes cluster resource usage.
- `k8s_check_resource_limits.sh`: Verifies CPU/Memory limits on all pods.
- `k8s_decode_secret.sh`: Decodes all keys in a Kubernetes secret.
- `k8s_unused_secrets_finder.sh`: Identifies secrets not currently used by any Pod or ServiceAccount.

### Docker Scripts
- `install_docker.sh`: Clean installation of the latest Docker.
- `docker_build_push.sh`: Advanced build and push with multi-tag support.
- `trivyScans.sh`: Vulnerability scanning using Trivy.
- `docker_tag_exists.sh`: Remote registry tag verification.
- `docker_image_size.sh`: Validates image size constraints.
- `docker_clean_unused.sh`: Safe pruning of unused resources.
- `docker_list_latest_images.sh`: Lists local Docker images using the 'latest' tag.

### Azure & Azure DevOps Scripts
- `az_devops_config.sh`: Configures CLI with Org URL and PAT.
- `az_devops_run_pipeline.sh`: Triggers and monitors a pipeline run.
- `az_repo_tag_watcher.sh`: Automated pipeline triggering based on Git tags.
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups.
- `az_script_advance.sh`: E2E project and pipeline setup.

### JFrog Scripts
- `jfrog_config.sh`: Server configuration for JFrog CLI.
- `jf_xray_scan.sh`: Security scans for artifacts and builds.
- `jf_node_config.sh` / `jf_python_config.sh`: Configures package managers for Artifactory.
- `jfrog_upload.sh` / `jfrog_download.sh`: High-level artifact management.

### GitHub Scripts
- `gh_create_release.sh`: Automated release creation via API.
- `gh_get_latest_release.sh`: Fetches the latest release tag.
- `commit_script.sh`: Streamlined add-commit-push workflow.
- `git_cleanup_merged_branches.sh`: Deletes local branches that have been merged into the default branch.

### Terraform Scripts
- `envsetup.sh`: Installs Terraform and dependencies.
- `tf_validate_all.sh`: Recursive module validation.
- `tf_check_fmt.sh`: Canonical formatting enforcement.

### AWS Scripts
- `aws_s3_sync.sh`: Syncs a local directory with an S3 bucket.
- `aws_list_old_ebs_snapshots.sh`: Lists EBS snapshots older than a specified number of days.

### General Utilities
- `check_sys_info.sh`: Linux system health summary.
- `check_disk_space.sh`: Monitoring with alerting thresholds.
- `check_ssl_expiry.sh`: Monitors SSL certificate expiration.
- `find_large_files.sh`: Identifies storage consumers.
- `send_slack_notification.sh`: Pipeline-integrated Slack alerts.
- `hadolint_scan.sh`: Dockerfile linting via Docker.
- `check_url_content.sh`: Waits for a URL to return 200 OK and verifies body content.

## 🏗️ Azure DevOps Templates
Located in `az_devops_templates/`, these follow a modular design:
- **`common/`**: Step-level templates for security, docker, and gitflow.
- **`jobs/`**: Parameterized job templates for multi-language builds and deployments.
- **`pipelines/`**: End-to-end example pipelines.

## 🛡️ Security

This repository follows **Sentinel** security principles:
- **Secret Management**: Mandatory use of environment variables for secrets.
- **Left-Shift**: Early integration of Gitleaks, Trivy, and Xray in all workflows.
- **Safe Logging**: Prevention of credential leakage in CI/CD logs.

## 🤝 Contributing

Feel free to submit pull requests with additional scripts or improvements. Please ensure new scripts follow the guidelines in `AGENTS.md`.

## 📜 License

MIT - See [LICENSE](LICENSE) for details. (All rights reserved, Made by Kobi Kuzi)
