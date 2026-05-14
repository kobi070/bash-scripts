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
- [🧠 Core Philosophies](#-core-philosophies)
- [📂 Repository Structure](#-repository-structure)
- [🛠️ Prerequisites](#️-prerequisites)
- [🔐 Environment Variables](#-environment-variables)
- [⚡ Quick Start](#-quick-start)
- [📜 Available Scripts](#-available-scripts)
- [🏗️ Azure DevOps Templates](#️-azure-devops-templates)
- [🛡️ Security](#️-security)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

---

## 🚀 Key Features

- **Modularity**: Small, single-purpose scripts and templates that can be easily composed.
- **Security-First**: Integrated secret scanning, vulnerability checks, and best practices for credential handling.
- **Performance Optimized**: Efficient shell scripting techniques to minimize overhead.
- **Cloud Native**: Native support for AWS, Azure, Docker, and Kubernetes.
- **CI/CD Ready**: Reusable Azure DevOps templates and GitHub API automation.
- **Standardized**: Consistent usage patterns, help functions, and error handling across all scripts.

## 🧠 Core Philosophies

This repository is built and maintained following two core personas:

### 🛡️ Sentinel (Security)
Prioritizes a "Security-First" approach to DevOps:
- **Left-Shift Security**: Integration of security checks (Gitleaks, Trivy, Xray) at the earliest stages.
- **Safe Logging**: Explicitly avoids verbose modes (like `curl -v`) that could leak sensitive headers.
- **Secure Credential Handling**: Prioritizes environment variables over positional arguments to prevent exposure in process lists and shell history.
- **Clean Configuration**: Avoids embedding secrets in persistent files, such as Git remote URLs.

### ⚡ Bolt (Performance)
Focuses on making automation as fast and efficient as possible:
- **Process Reduction**: Consolidates shell pipelines (e.g., using `sed` or `awk` instead of multiple `grep | head` calls) to reduce process forking overhead.
- **Git Plumbing**: Utilizes Git plumbing commands for faster and more robust automation compared to parsing porcelain output.
- **Native Tools**: Leverages built-in shell features (like `$SECONDS`) over external calls where possible.

## 📂 Repository Structure

The repository is organized into technology-specific directories:

- [argocd_scripts/](./argocd_scripts/): ArgoCD installation and app management.
- [aws_scripts/](./aws_scripts/): AWS CLI, S3 automation, and resource cleanup.
- [az_devops_templates/](./az_devops_templates/): Reusable YAML templates for Azure DevOps pipelines.
- [az_scripts/](./az_scripts/): Azure CLI and Azure DevOps automation.
- [docker_scripts/](./docker_scripts/): Docker environment management and security.
- [general_scripts/](./general_scripts/): System utilities, versioning, and monitoring.
- [github_scripts/](./github_scripts/): GitHub API and Git workflow automation.
- [jfrog_scripts/](./jfrog_scripts/): JFrog CLI and Artifactory management.
- [k8s_scripts/](./k8s_scripts/): Kubernetes cluster initialization and resource management.
- [terraform_scripts/](./terraform_scripts/): Terraform environment setup and validation.

## 🛠️ Prerequisites

Ensure you have the relevant CLI tools installed for the scripts you intend to use:

| Tool | Purpose | Targeted Scripts |
|------|---------|------------------|
| **Bash** | Execution environment | All `.sh` scripts |
| **jq** | JSON parsing | Most scripts (Essential) |
| **kubectl** | K8s management | `k8s_scripts/`, `argocd_scripts/` |
| **Docker** | Containerization | `docker_scripts/`, `general_scripts/hadolint_scan.sh` |
| **Azure CLI** | Azure & ADO | `az_scripts/` (Requires `azure-devops` extension) |
| **AWS CLI** | AWS management | `aws_scripts/` |
| **JFrog CLI** | Artifact mgmt | `jfrog_scripts/` |
| **Terraform** | IaC management | `terraform_scripts/` |
| **curl** | API interactions | `github_scripts/`, `jfrog_scripts/`, `general_scripts/` |

## 🔐 Environment Variables

Scripts prioritize environment variables for security. Common variables include:

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

## 📜 Available Scripts

### ☸️ Kubernetes Scripts ([Details](./k8s_scripts/README.md))
- `init_k8s.sh`: Kubernetes initialization and health check.
- `k8s_wait_ready.sh`: Waits for resources to reach a ready state.
- `k8s_node_resource_usage.sh`: Summarizes cluster resource usage.
- `k8s_decode_secret.sh`: Decodes all keys in a Kubernetes secret.
- `k8s_find_unused_pvcs.sh`: Identifies unused PersistentVolumeClaims.
- `k8s_check_resource_limits.sh`: Verifies resource limits in a namespace.
- `k8s_pod_restart_detector.sh`: Identifies frequently restarting pods.
- `k8s_pod_logs_by_label.sh`: Aggregates logs from pods by label.

### 🐳 Docker Scripts ([Details](./docker_scripts/README.md))
- `install_docker.sh`: Clean installation of the latest Docker.
- `docker_build_push.sh`: Advanced build and push with multi-tag support.
- `trivyScans.sh`: Vulnerability scanning using Trivy.
- `docker_tag_exists.sh`: Remote registry tag verification.
- `docker_clean_unused.sh`: Safe pruning of unused resources.
- `docker_image_size.sh`: Validates image size against limits.

### ☁️ Azure & Azure DevOps Scripts ([Details](./az_scripts/README.md))
- `az_devops_config.sh`: Configures CLI with Org URL and PAT.
- `az_devops_run_pipeline.sh`: Triggers and monitors a pipeline run.
- `az_devops_wait_pipeline.sh`: Waits for a specific pipeline run completion.
- `az_pipeline_status.sh`: Checks status and result of a pipeline run.
- `az_repo_tag_watcher.sh`: Automated pipeline triggering based on Git tags.
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups.
- `az_list_repos.sh`: Lists all repositories in a project.
- `az_devops_list_pipelines.sh`: Lists all pipelines in a project.

### 📦 JFrog Scripts ([Details](./jfrog_scripts/README.md))
- `jfrog_config.sh`: Server configuration for JFrog CLI.
- `jf_xray_scan.sh`: Security scans for artifacts and builds.
- `jf_node_config.sh` / `jf_python_config.sh`: Configures package managers for Artifactory.
- `jfrog_upload.sh` / `jfrog_download.sh`: High-level artifact management.

### 🐙 GitHub Scripts ([Details](./github_scripts/README.md))
- `gh_create_release.sh`: Automated release creation via API.
- `gh_get_latest_release.sh`: Fetches the latest release tag.
- `gh_download_release_asset.sh`: Downloads specific assets from a release.
- `gh_list_pull_requests.sh`: Lists open PRs and their status.
- `gh_list_collaborators.sh`: Lists repository collaborators.
- `init_repo.sh`: Initializes a new Git repository with best practices.

### 🏗️ Terraform Scripts ([Details](./terraform_scripts/README.md))
- `envsetup.sh`: Installs Terraform and dependencies.
- `tf_validate_all.sh`: Recursive module validation.
- `tf_check_fmt.sh`: Canonical formatting enforcement.

### 🐙 ArgoCD Scripts ([Details](./argocd_scripts/README.md))
- `install-argocd.sh`: Automated ArgoCD installation.
- `argocd_app_sync.sh`: Syncs ArgoCD applications and waits for health.

### ☁️ AWS Scripts ([Details](./aws_scripts/README.md))
- `aws_s3_sync.sh`: Robust S3 synchronization with dry-run support.
- `aws_find_unused_ebs.sh`: Identifies unattached EBS volumes.

### 🛠️ General Utilities ([Details](./general_scripts/README.md))
- `check_sys_info.sh`: Linux system health summary.
- `check_zombie_processes.sh`: Detects zombie processes.
- `wait_for_url.sh`: Polls a URL until it returns 200 OK.
- `bump_version.sh`: Automates version bumping in files.
- `find_large_files.sh`: Identifies storage consumers.
- `send_slack_notification.sh`: Pipeline-integrated Slack alerts.
- `hadolint_scan.sh`: Dockerfile linting via Docker.

## 🏗️ Azure DevOps Templates ([Details](./az_devops_templates/README.md))

Located in `az_devops_templates/`, these follow a modular design:

- **`common/`**: Step-level templates for security (Gitleaks, Trivy, Xray), docker, and gitflow.
- **`jobs/`**: Parameterized job templates for multi-language builds and deployments (K8s, VM, Web App).
- **`pipelines/`**: End-to-end example pipelines and utility maintenance scripts.

## 🛡️ Security

This repository follows strict security principles to ensure automation is safe and reliable:
- **Secret Scanning**: Mandatory Gitleaks integration in pipelines.
- **Vulnerability Scanning**: Automated Trivy and JFrog Xray scans for images and artifacts.
- **Safe Environment**: Implementation of best practices for secret handling as documented in [Sentinel Principles](#-sentinel-security).

## 🤝 Contributing

Feel free to submit pull requests with additional scripts or improvements. Please ensure new scripts follow the guidelines in `AGENTS.md`.

## 📜 License

MIT - See [LICENSE](LICENSE) for details. (All rights reserved, Made by Kobi Kuzi)
