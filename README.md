# DevOps Automation Scripts & Templates

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-DevOps-0078D4?logo=azure-devops&logoColor=white)

A comprehensive collection of specialized DevOps scripts and Azure DevOps YAML templates designed to automate installations, configurations, and CI/CD workflows across various environments.

---

## 📑 Table of Contents

- [🚀 Key Features](#-key-features)
- [📂 Repository Structure](#-repository-structure)
- [🛠️ Prerequisites](#️-prerequisites)
- [🔐 Environment Variables](#-environment-variables)
- [⚡ Quick Start](#-quick-start)
- [📜 Available Scripts](#-available-scripts)
- [🏗️ Azure DevOps Templates](#️-azure-devops-templates)
- [⚡ Performance (Bolt)](#-performance-bolt)
- [🛡️ Security (Sentinel)](#️-security-sentinel)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

---

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

## 🔐 Environment Variables

Many scripts prioritize environment variables for security and automation. Common variables include:

| Variable | Purpose |
|----------|---------|
| `AZ_DEVOPS_PAT` | Personal Access Token for Azure DevOps. |
| `GITHUB_TOKEN` | Token for GitHub API operations. |
| `JF_AUTH_TOKEN` | Authentication token for JFrog CLI. |
| `SLACK_WEBHOOK_URL` | Webhook URL for Slack notifications. |
| `AZURE_DEVOPS_EXT_PAT` | Used by Azure CLI `azure-devops` extension. |

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

### ☸️ Kubernetes Scripts
- `init_k8s.sh`: Kubernetes initialization and health check.
- `minikube_install.sh`: Automated Minikube installation.
- `minikube_start.sh` / `minikube_stop.sh`: Minikube lifecycle management.
- `k8s_wait_ready.sh`: Waits for resources to reach a ready state.
- `k8s_node_resource_usage.sh`: Summarizes cluster resource usage.
- `k8s_decode_secret.sh`: Decodes all keys in a Kubernetes secret.
- `k8s_create_ns.sh` / `del_ns.sh`: Quick namespace management.
- `k8s_pod_restart_detector.sh`: Identifies frequently restarting pods.
- `k8s_pod_logs_by_label.sh`: Aggregates logs from pods by label.
- `k8s_check_resource_limits.sh`: Verifies resource limits on pods.
- `k8s_find_unused_pvcs.sh`: Identifies unused PersistentVolumeClaims.

### 🐳 Docker Scripts
- `install_docker.sh`: Clean installation of the latest Docker.
- `check_docker.sh`: Verifies Docker and Compose installation.
- `docker_login.sh`: Registry authentication helper.
- `docker_build_push.sh`: Advanced build and push with multi-tag support.
- `trivyScans.sh`: Vulnerability scanning using Trivy.
- `docker_tag_exists.sh`: Remote registry tag verification.
- `docker_image_size.sh`: Validates image size limits.
- `docker_clean_unused.sh`: Safe pruning of unused resources (images, volumes, networks).
- `docker_get_container_ip.sh`: Retrieves container IP address.

### ☁️ Azure & Azure DevOps Scripts
- `az_devops_config.sh`: Configures CLI with Org URL and PAT.
- `az_devops_run_pipeline.sh`: Triggers and monitors a pipeline run.
- `az_devops_list_pipelines.sh`: Lists all pipelines in a project.
- `az_pipeline_status.sh`: Checks status of a specific pipeline run.
- `az_repo_tag_watcher.sh`: Automated pipeline triggering based on Git tags.
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups.
- `az_list_repos.sh`: Lists all repositories in a project.
- `az_script_advance.sh`: E2E project and pipeline setup.

### 📦 JFrog Scripts
- `jfrog_config.sh`: Server configuration for JFrog CLI.
- `jf_xray_scan.sh`: Security scans for artifacts and builds.
- `jf_node_config.sh` / `jf_python_config.sh`: Configures package managers for Artifactory.
- `jfrog_upload.sh` / `jfrog_download.sh`: High-level artifact management.
- `jfrog_search.sh` / `delete.sh`: Artifact discovery and safe removal.
- `jf_docker_push.sh`: Pushes Docker images to Artifactory.
- `upload_generic.sh` / `pull_generic.sh`: API-based artifact management via curl.

### 🐙 GitHub Scripts
- `gh_create_release.sh`: Automated release creation via API.
- `gh_get_latest_release.sh`: Fetches the latest release tag.
- `gh_download_release_asset.sh`: Downloads assets from releases.
- `gh_list_pull_requests.sh`: Lists open PRs and their status.
- `gh_list_collaborators.sh`: Lists repository collaborators.
- `init_repo.sh`: Initializes a new Git repository.
- `commit_script.sh`: Streamlined add-commit-push workflow.
- `logs_script.sh`: Formatted Git log display.

### 🏗️ Terraform Scripts
- `envsetup.sh`: Installs Terraform and dependencies.
- `tr_init.sh`: Environment readiness check for Terraform.
- `tf_validate_all.sh`: Recursive module validation.
- `tf_check_fmt.sh`: Canonical formatting enforcement.

### 🐙 ArgoCD Scripts
- `install-argocd.sh`: Automated ArgoCD installation.
- `argocd_app_sync.sh`: Syncs ArgoCD applications and waits for health.
- `argocd_list_apps.sh`: Lists all apps and their status.

### ☁️ AWS Scripts
- `aws_s3_sync.sh`: Robust S3 synchronization with dry-run support.
- `aws_find_unused_ebs.sh`: Lists unattached EBS volumes.

### 🛠️ General Utilities
- `check_sys_info.sh`: Linux system health summary.
- `check_disk_space.sh`: Monitoring with alerting thresholds.
- `check_ssl_expiry.sh`: Monitors SSL certificate expiration.
- `check_zombie_processes.sh`: Detects zombie processes.
- `find_large_files.sh`: Identifies storage consumers.
- `kill_proc.sh`: Kills process by name or port.
- `bump_version.sh`: Automates version bumping in files.
- `validate_env_vars.sh`: Ensures required environment variables are set.
- `wait_for_url.sh`: Polls a URL until it returns 200 OK.
- `send_slack_notification.sh`: Pipeline-integrated Slack alerts.
- `hadolint_scan.sh`: Dockerfile linting via Docker.
- `get_helm.sh`: Automated Helm CLI installation.

## 🏗️ Azure DevOps Templates

Located in `az_devops_templates/`, these follow a modular design:

- **`common/`**: Step-level templates for security (Gitleaks, Trivy, Xray), docker, and gitflow.
- **`jobs/`**: Parameterized job templates for multi-language builds (Node.js, Python, .NET, C++) and deployments (K8s, VM, Web App).
- **`pipelines/`**: End-to-end example pipelines and utility maintenance scripts.

## ⚡ Performance (Bolt)

This repository follows **Bolt** performance principles:

- **Process Reduction**: Minimizing shell process forks by consolidating pipelines (e.g., using a single `awk` or `sed` command instead of multiple pipes).
- **Git Plumbing**: Utilizing Git plumbing commands (like `git rev-parse`) instead of parsing porcelain output for faster and more robust automation.
- **Native CLI Querying**: Prioritizing native tool features (like `az --query`) for data extraction to reduce intermediate processing steps.
- **Efficient Looping**: Using built-in shell variables like `$SECONDS` for timing and `mapfile` for robust line processing.

## 🛡️ Security (Sentinel)

This repository follows **Sentinel** security principles:

- **Left-Shift Security**: Mandatory integration of security checks (Gitleaks, Trivy, Xray) at the earliest stages of the lifecycle.
- **Secret Scanning**: Gitleaks is integrated to prevent accidental credential leaks.
- **Vulnerability Scanning**: Automated container and artifact scanning using Trivy and JFrog Xray.
- **Safe Logging**: Explicit avoidance of verbose modes (like `curl -v`) and sensitive data redaction in CI/CD logs.
- **Credential Handling**: Strict prioritization of environment variables over positional arguments and avoidance of tokens in persistent Git configurations.

## 🤝 Contributing

Feel free to submit pull requests with additional scripts or improvements. Please ensure new scripts follow the guidelines in `AGENTS.md`.

## 📜 License

MIT - See [LICENSE](LICENSE) for details. (All rights reserved, Made by Kobi Kuzi)
