# DevOps Automation Scripts & Templates
# ⚡ DevOps Automation Hub 🛡️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
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
| Tool | Purpose |
|------|---------|
| **Bash** | Core execution environment (uses `set -euo pipefail`). |
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-623CE4?logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-2088FF?logo=github-actions&logoColor=white)

A high-performance, security-focused collection of specialized DevOps scripts and Azure DevOps YAML templates designed to automate installations, cloud configurations, and complex CI/CD workflows.

---

## 📑 Table of Contents

- [🚀 Key Features](#-key-features)
- [📂 Repository Structure](#-repository-structure)
- [🛠️ Prerequisites](#-prerequisites)
- [🔐 Environment Variables](#-environment-variables)
- [⚡ Quick Start](#-quick-start)
- [📜 Available Scripts](#-available-scripts)
  - [☸️ Kubernetes](#-kubernetes-scripts)
  - [🐳 Docker](#-docker-scripts)
  - [☁️ Azure & Azure DevOps](#-azure-azure-devops-scripts)
  - [📦 JFrog Artifactory](#-jfrog-scripts)
  - [🐙 GitHub & Git](#-github-git-scripts)
  - [🏗️ Terraform](#-terraform-scripts)
  - [🐙 ArgoCD](#-argocd-scripts)
  - [☁️ AWS](#-aws-scripts)
  - [🛠️ General Utilities](#-general-utilities)
- [🏗️ Azure DevOps Templates](#-azure-devops-templates)
- [⚡ Performance (Bolt)](#-performance-bolt)
- [🛡️ Security (Sentinel)](#-security-sentinel)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)
- [🛠️ Tech Stack](#tech-stack)
- [🚀 Key Features](#key-features)
- [📂 Repository Structure](#repository-structure)
- [🛠️ Prerequisites](#prerequisites)
- [🔐 Environment Variables](#environment-variables)
- [⚡ Quick Start](#quick-start)
- [📜 Available Scripts](#available-scripts)
  - [☸️ Kubernetes](#kubernetes-scripts)
  - [🐳 Docker](#docker-scripts)
  - [☁️ Azure & Azure DevOps](#azure--azure-devops-scripts)
  - [📦 JFrog Artifactory](#jfrog-scripts)
  - [🐙 GitHub & Git](#github--git-scripts)
  - [🏗️ Terraform](#terraform-scripts)
  - [🐙 ArgoCD](#argocd-scripts)
  - [☁️ AWS](#aws-scripts)
  - [🛠️ General Utilities](#general-utilities)
- [🏗️ Azure DevOps Templates](#azure-devops-templates)
- [⚡ Performance (Bolt)](#performance-bolt)
- [🛡️ Security (Sentinel)](#security-sentinel)
- [🤝 Contributing](#contributing)
- [📜 License](#license)

---

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)
![Azure](https://img.shields.io/badge/azure-%230072C6.svg?style=flat&logo=azure-devops&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=flat&logo=githubactions&logoColor=white)
![ArgoCD](https://img.shields.io/badge/argocd-%23ef7b4d.svg?style=flat&logo=argocd&logoColor=white)
![JFrog](https://img.shields.io/badge/JFrog-Green?style=flat&logo=jfrog&logoColor=white)

---

<h2 id="tech-stack">🛠️ Tech Stack</h2>

---

<h2 id="key-features">🚀 Key Features</h2>

- **⚡ Bolt Performance**: Optimized shell scripts with minimized process forks and efficient Git plumbing.
- **🛡️ Sentinel Security**: Integrated "left-shift" security with secret scanning and vulnerability checks.
- **🏗️ Modular Architecture**: Reusable, parameterized Azure DevOps templates and single-purpose scripts.
- **☁️ Multi-Cloud & Tooling**: Native support for AWS, Azure, Docker, Kubernetes, JFrog, and Terraform.
- **📜 Standardized**: Consistent help functions, error handling (`set -euo pipefail`), and usage patterns.

## 📂 Repository Structure

```text
.
├── argocd_scripts/          # ArgoCD installation and app management
├── aws_scripts/             # AWS resource monitoring and S3 sync
├── az_devops_templates/     # Reusable YAML templates for pipelines
├── az_scripts/              # Azure CLI and DevOps automation
├── docker_scripts/          # Docker lifecycle and security scans
├── general_scripts/         # System health and general utilities
├── github_scripts/          # GitHub API and Git workflow helpers
├── jfrog_scripts/           # JFrog CLI and Artifactory operations
├── k8s_scripts/             # K8s cluster management and debugging
└── terraform_scripts/       # Terraform environment setup and validation
```

- [argocd_scripts/](./argocd_scripts/): ArgoCD installation and GitOps app management.
- [aws_scripts/](./aws_scripts/): AWS CLI automation and resource monitoring.
- [az_devops_templates/](./az_devops_templates/): Reusable YAML templates for pipelines.
- [az_scripts/](./az_scripts/): Azure CLI and Azure DevOps E2E automation.
- [docker_scripts/](./docker_scripts/): Environment setup, image optimization, and security.
- [general_scripts/](./general_scripts/): System utilities, versioning, and monitoring tools.
- [github_scripts/](./github_scripts/): GitHub API automation and Git workflow helpers.
- [jfrog_scripts/](./jfrog_scripts/): JFrog CLI management and Artifactory operations.
- [k8s_scripts/](./k8s_scripts/): Cluster initialization and resource management.
- [terraform_scripts/](./terraform_scripts/): Environment setup and recursive validation.

## 🛠️ Prerequisites
<h2 id="repository-structure">📂 Repository Structure</h2>

```text
.
├── argocd_scripts/      # ArgoCD installation and GitOps app management
├── aws_scripts/         # AWS CLI automation and resource monitoring
├── az_devops_templates/ # Reusable YAML templates for pipelines
│   ├── common/          # Step-level templates (security, docker, etc.)
│   ├── jobs/            # Parameterized job templates
│   └── pipelines/       # E2E pipeline examples and utilities
├── az_scripts/          # Azure CLI and Azure DevOps E2E automation
├── docker_scripts/      # Environment setup, image optimization, and security
├── general_scripts/     # System utilities, versioning, and monitoring tools
├── github_scripts/      # GitHub API automation and Git workflow helpers
├── jfrog_scripts/       # JFrog CLI management and Artifactory operations
├── k8s_scripts/         # Cluster initialization and resource management
└── terraform_scripts/   # Environment setup and recursive validation
```

<h2 id="prerequisites">🛠️ Prerequisites</h2>

Ensure the following tools are installed based on your requirements:

| Tool | Purpose |
|------|---------|
| **Bash 4.0+** | Core execution environment (uses `mapfile`, `set -euo pipefail`). |
| **jq** | Essential for JSON parsing across almost all scripts. |
| **Docker** | For `docker_scripts`, Trivy scans, and Hadolint. |
| **kubectl** | For `k8s_scripts` and `argocd_scripts`. |
| **Azure CLI** | For `az_scripts` (requires `azure-devops` extension). |
| **AWS CLI** | For `aws_scripts`. |
| **JFrog CLI** | For `jfrog_scripts`. |
| **Terraform** | For `terraform_scripts`. |

## ⚡ Quick Start
| **JFrog CLI** | For `jfrog_scripts` (`jf` or `jfrog`). |
| **Terraform** | For `terraform_scripts`. |

<h2 id="environment-variables">🔐 Environment Variables</h2>

Scripts prioritize environment variables for security. Common variables include:
Many scripts prioritize environment variables for secure automation:

| Variable | Purpose |
|----------|---------|
| `AZ_DEVOPS_PAT` | PAT for Azure DevOps CLI configuration. |
| `AZURE_DEVOPS_EXT_PAT` | PAT for non-interactive Azure CLI operations. |
| `GITHUB_TOKEN` | Token for GitHub API operations. |
| `JF_AUTH_TOKEN` / `JFROG_API_KEY` | Authentication for JFrog Artifactory. |
| `SLACK_WEBHOOK_URL` | Webhook for pipeline notifications. |
| `DOCKER_USERNAME` / `DOCKER_PASSWORD` | Docker registry credentials. |

<h2 id="quick-start">⚡ Quick Start</h2>

1. **Clone the repo**:
   ```bash
   git clone https://github.com/your-repo/devops-automation.git
   cd devops-automation
   ```

2. **Configure Azure DevOps environment** (Example):
2. **Run a system check**:
2. **Run a system health check**:
   ```bash
   # Set your PAT securely
   export AZ_DEVOPS_PAT="your_personal_access_token"

   # Run the configuration script
   ./az_scripts/az_devops_config.sh https://dev.azure.com/your-organization/
   ```

3. **Run a system health check**:
3. **Check Kubernetes resources**:
   ```bash
   ./k8s_scripts/k8s_node_resource_usage.sh
   ```

## 📜 Available Scripts

### ☸️ Kubernetes Scripts ([Details](./k8s_scripts/README.md))
### Kubernetes Scripts
- `init_k8s.sh`: Kubernetes initialization and health check.
- `k8s_wait_ready.sh`: Waits for resources to reach a ready state.
- `k8s_node_resource_usage.sh`: Summarizes cluster resource usage.
- `k8s_check_resource_limits.sh`: Verifies CPU/Memory limits on all pods.
- `k8s_decode_secret.sh`: Decodes all keys in a Kubernetes secret.
- `k8s_secret_expiry_check.sh`: Identifies expiring TLS secrets.
- `k8s_find_unused_pvcs.sh`: Identifies unused PersistentVolumeClaims.
- `k8s_check_resource_limits.sh`: Verifies resource limits in a namespace.
- `k8s_pod_restart_detector.sh`: Identifies frequently restarting pods.
- `k8s_pod_logs_by_label.sh`: Aggregates logs from pods by label.

### 🐳 Docker Scripts ([Details](./docker_scripts/README.md))
- `k8s_copy_secret.sh`: Copies a secret between namespaces.

### 🐳 Docker Scripts
- `k8s_create_ns.sh` / `del_ns.sh`: Quick namespace management.
- `k8s_pod_restart_detector.sh`: Identifies frequently restarting pods.
- `k8s_pod_logs_by_label.sh`: Aggregates logs from pods by label.
- `k8s_check_resource_limits.sh`: Verifies resource limits on pods.
- `k8s_find_unused_pvcs.sh`: Identifies unused PersistentVolumeClaims.
- `k8s_node_drain_helper.sh`: Assess node drain impact (PDBs, local storage).
- `k8s_unused_secrets_finder.sh`: Identifies secrets not currently used by any Pod or ServiceAccount.

### Docker Scripts
- `install_docker.sh`: Clean installation of the latest Docker.
- `docker_build_push.sh`: Advanced build and push with multi-tag support.
- `trivyScans.sh`: Vulnerability scanning using Trivy.
- `docker_layer_analysis.sh`: Analyzes image layer sizes and commands.
- `docker_tag_exists.sh`: Remote registry tag verification.
- `docker_image_size.sh`: Validates image size limits.
- `docker_clean_unused.sh`: Safe pruning of unused resources (images, volumes, networks).
- `docker_get_container_ip.sh`: Retrieves container IP address.
- `docker_inspect_security.sh`: Container security audit (root, privileged, mounts).
- `docker_image_size.sh`: Validates image size constraints.
- `docker_clean_unused.sh`: Safe pruning of unused resources.
- `docker_layer_size_analyzer.sh`: Analyzes Docker image layers.
- `docker_image_size.sh`: Validates image size against limits.

### ☁️ Azure & Azure DevOps Scripts ([Details](./az_scripts/README.md))
- `docker_list_latest_images.sh`: Lists local Docker images using the 'latest' tag.

### Azure & Azure DevOps Scripts
- `az_devops_config.sh`: Configures CLI with Org URL and PAT.
- `az_devops_run_pipeline.sh`: Triggers and monitors a pipeline run.
- `az_devops_wait_pipeline.sh`: Waits for a specific pipeline run completion.
- `az_pipeline_status.sh`: Checks status and result of a pipeline run.
- `az_repo_tag_watcher.sh`: Automated pipeline triggering based on Git tags.
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups.
- `az_list_repos.sh`: Lists all repositories in a project.
- `az_devops_list_pipelines.sh`: Lists all pipelines in a project.

### 📦 JFrog Scripts ([Details](./jfrog_scripts/README.md))
### JFrog Scripts
- `jfrog_config.sh`: Server configuration for JFrog CLI.
- `jf_xray_scan.sh`: Security scans for artifacts and builds.
- `jf_node_config.sh` / `jf_python_config.sh`: Configures package managers for Artifactory.
- `jfrog_upload.sh` / `jfrog_download.sh`: High-level artifact management.
- `jfrog_search.sh` / `delete.sh`: Artifact discovery and safe removal.
- `jf_docker_push.sh`: Pushes Docker images to Artifactory.
- `upload_generic.sh` / `pull_generic.sh`: API-based artifact management via curl.
- `jf_cleanup_old_artifacts.sh`: Automated artifact cleanup by age.

### 🐙 GitHub Scripts ([Details](./github_scripts/README.md))
- `gh_create_release.sh`: Automated release creation via API.
- `gh_get_latest_release.sh`: Fetches the latest release tag.
- `gh_download_release_asset.sh`: Downloads specific assets from a release.
- `gh_list_pull_requests.sh`: Lists open PRs and their status.
- `gh_list_collaborators.sh`: Lists repository collaborators.
- `init_repo.sh`: Initializes a new Git repository with best practices.

### 🏗️ Terraform Scripts ([Details](./terraform_scripts/README.md))
### GitHub Scripts
- `gh_create_release.sh`: Automated release creation via API.
- `gh_get_latest_release.sh`: Fetches the latest release tag.
- `gh_workflow_failure_logs.sh`: Fetches logs for failed workflow runs.
- `gh_download_release_asset.sh`: Downloads assets from releases.
- `gh_list_pull_requests.sh`: Lists open PRs and their status.
- `gh_workflow_stats.sh`: Summarizes workflow run statuses.
- `gh_list_collaborators.sh`: Lists repository collaborators.
- `gh_pr_size_checker.sh`: Categorizes PRs by size (XS-XL).
- `init_repo.sh`: Initializes a new Git repository.
- `commit_script.sh`: Streamlined add-commit-push workflow.
- `git_cleanup_merged_branches.sh`: Deletes local branches that have been merged into the default branch.

### Terraform Scripts
- `envsetup.sh`: Installs Terraform and dependencies.
- `tf_validate_all.sh`: Recursive module validation.
- `tf_check_fmt.sh`: Canonical formatting enforcement.

### 🐙 ArgoCD Scripts ([Details](./argocd_scripts/README.md))
- `install-argocd.sh`: Automated ArgoCD installation.
- `argocd_app_sync.sh`: Syncs ArgoCD applications and waits for health.

### ☁️ AWS Scripts ([Details](./aws_scripts/README.md))
- `aws_s3_sync.sh`: Robust S3 synchronization with dry-run support.
- `aws_sg_audit.sh`: Audits Security Groups for open rules.
- `aws_find_unused_ebs.sh`: Identifies unattached EBS volumes.

### 🛠️ General Utilities ([Details](./general_scripts/README.md))
- `check_sys_info.sh`: Linux system health summary.
- `check_zombie_processes.sh`: Detects zombie processes.
- `wait_for_url.sh`: Polls a URL until it returns 200 OK.
- `bump_version.sh`: Automates version bumping in files.
- `aws_iam_admin_audit.sh`: Audits users/groups for AdministratorAccess.
- `aws_find_unused_ebs.sh`: Lists unattached EBS volumes.
- `aws_list_iam_users_last_login.sh`: Lists IAM user activity for cleanup.
### AWS Scripts
- `aws_s3_sync.sh`: Syncs a local directory with an S3 bucket.
- `aws_list_old_ebs_snapshots.sh`: Lists EBS snapshots older than a specified number of days.

### General Utilities
- `check_sys_info.sh`: Linux system health summary.
- `check_disk_space.sh`: Monitoring with alerting thresholds.
- `check_ssl_expiry.sh`: Monitors SSL certificate expiration.
- `multi_url_monitor.sh`: Health-checks multiple URLs with alerting.
- `find_large_files.sh`: Identifies storage consumers.
- `send_slack_notification.sh`: Pipeline-integrated Slack alerts.
- `url_health_summary.sh`: Reports status and latency for URLs.
- `hadolint_scan.sh`: Dockerfile linting via Docker.
- `check_url_content.sh`: Waits for a URL to return 200 OK and verifies body content.

## 🏗️ Azure DevOps Templates ([Details](./az_devops_templates/README.md))

## 🏗️ Azure DevOps Templates
Located in `az_devops_templates/`, these follow a modular design:
- **`common/`**: Step-level templates for security, docker, and gitflow.
- **`jobs/`**: Parameterized job templates for multi-language builds and deployments.
- **`pipelines/`**: End-to-end example pipelines.

- **`common/`**: Step-level templates for security (Gitleaks, Trivy, Xray), docker, and gitflow.
- **`jobs/`**: Parameterized job templates for multi-language builds and deployments (K8s, VM, Web App).
- **`pipelines/`**: End-to-end example pipelines and utility maintenance scripts.

## 🛡️ Security

This repository follows strict security principles to ensure automation is safe and reliable:
- **Secret Scanning**: Mandatory Gitleaks integration in pipelines.
- **Vulnerability Scanning**: Automated Trivy and JFrog Xray scans for images and artifacts.
- **Safe Environment**: Implementation of best practices for secret handling as documented in [Sentinel Principles](#-sentinel-security).
## 🛡️ Security

This repository follows **Sentinel** security principles:
- **Secret Management**: Mandatory use of environment variables for secrets.
- **Left-Shift**: Early integration of Gitleaks, Trivy, and Xray in all workflows.
- **Safe Logging**: Prevention of credential leakage in CI/CD logs.

## 🤝 Contributing

Feel free to submit pull requests with additional scripts or improvements. Please ensure new scripts follow the guidelines in `AGENTS.md`.

## 📜 License
3. **Initialize a Kubernetes environment**:
   ```bash
   ./general_scripts/check_sys_info.sh
   ```

4. **Initialize a Kubernetes environment**:
   ```bash
   ./k8s_scripts/init_k8s.sh
   ```

---

<h2 id="available-scripts">📜 Available Scripts</h2>

<details id="kubernetes-scripts">
<summary>☸️ Kubernetes Scripts</summary>

- `init_k8s.sh`: Kubernetes environment initialization and health check.
- `minikube_install.sh`: Automated Minikube installation on Linux.
- `minikube_start.sh` / `minikube_stop.sh` / `minikube_status.sh`: Minikube lifecycle management.
- `k8s_wait_ready.sh`: Waits for deployments/statefulsets to reach a ready state.
- `k8s_node_resource_usage.sh`: Summarizes CPU/Memory usage across nodes.
- `k8s_decode_secret.sh`: Decodes all Base64 keys in a Kubernetes secret.
- `k8s_create_ns.sh` / `k8s_del_ns.sh`: Quick namespace management.
- `k8s_pod_restart_detector.sh`: Identifies frequently restarting pods.
- `k8s_pod_logs_by_label.sh`: Aggregates logs from pods matching a label.
- `k8s_check_resource_limits.sh`: Verifies resource limits in a namespace.
- `k8s_find_unused_pvcs.sh`: Identifies unused PersistentVolumeClaims.
- `k8s_orphaned_resources.sh`: Heuristic discovery of unused ConfigMaps and Secrets.
</details>

<details id="docker-scripts">
<summary>🐳 Docker Scripts</summary>
- `k8s_audit_pdb.sh`: Identifies workloads missing PodDisruptionBudgets.

- `install_docker.sh`: Clean installation of the latest Docker Engine.
- `check_docker.sh`: Verifies Docker and Docker Compose availability.
- `docker_login.sh`: Secure registry authentication helper.
- `docker_build_push.sh`: Advanced build/push with multi-tag support.
- `trivyScans.sh`: Vulnerability scanning using Trivy.
- `docker_tag_exists.sh`: Remote registry tag verification.
- `docker_image_size.sh`: Validates image size limits.
- `docker_clean_unused.sh`: Prunes unused images, volumes, and networks.
- `docker-vol-prune.sh` / `docker-net-prune.sh`: Targeted resource pruning.
- `clean_docker_images.sh` / `clean_docker_ps.sh`: Quick cleanup scripts.
- `docker_audit_security.sh`: Lightweight security audit for running containers.
- `docker_get_container_ip.sh`: Retrieves the IP of a running container.
- `docker_root_check.sh`: Scans for containers running as root.
- `docker_push_to_repo.sh`: Pushes images to a target repository.
- `docker-tag-push.sh` / `docker-tag-push-from-file.sh`: Tag and push utilities.
</details>

<details id="azure--azure-devops-scripts">
<summary>☁️ Azure & Azure DevOps Scripts</summary>

- `az_devops_config.sh`: Configures CLI with Org URL and PAT.
- `az_devops_run_pipeline.sh` / `az_devops_wait_pipeline.sh`: Triggers and monitors runs.
- `az_devops_list_pipelines.sh`: Lists all pipelines in a project.
- `az_pipeline_status.sh`: Detailed status of a specific pipeline run.
- `az_repo_tag_watcher.sh`: Triggers pipelines based on new Git tags.
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups.
- `az_list_repos.sh`: Lists all repositories in a project.
- `az_script.sh`: Basic project and repo setup.
- `az_script_advance.sh`: E2E project, repo, and pipeline setup.
- `az_script_with_user.sh`: Interactive project setup wizard.
</details>

<details id="jfrog-scripts">
<summary>📦 JFrog Scripts</summary>

### ☁️ AWS Scripts
- `aws_s3_sync.sh`: Robust S3 synchronization with dry-run support.
- `aws_find_unused_ebs.sh`: Identifies unattached EBS volumes.
- `aws_iam_key_age.sh`: Identifies unrotated IAM access keys.

### 📦 JFrog Scripts
- `jfrog_config.sh`: Server configuration for JFrog CLI.
- `jf_xray_scan.sh`: Security scans for artifacts and builds.
- `jf_node_config.sh` / `jf_python_config.sh`: Artifactory package manager setup.
- `jfrog_upload.sh` / `jfrog_download.sh`: High-level artifact management.
- `jfrog_search.sh` / `jfrog_delete.sh`: Artifact discovery and safe removal.
- `jf_docker_push.sh`: Pushes Docker images to Artifactory.
- `jf_release_bundle.sh`: Manages JFrog Release Bundles.
- `upload_generic.sh` / `pull_generic.sh`: API-based management via curl.
</details>

<details id="github--git-scripts">
<summary>🐙 GitHub & Git Scripts</summary>

- `gh_create_release.sh`: Automated release creation via API.
- `gh_get_latest_release.sh`: Fetch the latest release tag.
- `gh_download_release_asset.sh`: Downloads specific release assets.
- `gh_list_pull_requests.sh`: Lists open PRs and their status.
- `gh_pr_stats.sh`: Calculates average time-to-merge for PRs.
- `gh_list_collaborators.sh`: Lists repository collaborators.
- `gh_workflow_stats.sh`: Analyzes GitHub Actions workflow statistics.
- `init_repo.sh`: Initializes a new Git repository with best practices.
- `commit_script.sh` / `commit_script_no_push.sh`: Streamlined commit workflows.
- `logs_script.sh`: Colorized and formatted Git log display.
- `create_command_alias.sh` / `check_alias.sh`: Git alias management.
</details>

<details id="terraform-scripts">
<summary>🏗️ Terraform Scripts</summary>

- `envsetup.sh`: Installs Terraform and environment dependencies.
- `tr_init.sh`: Environment readiness check for Terraform.
- `tf_validate_all.sh`: Recursive module validation.
- `tf_check_fmt.sh`: Canonical formatting enforcement.
</details>

<details id="argocd-scripts">
<summary>🐙 ArgoCD Scripts</summary>

- `install-argocd.sh`: Automated ArgoCD installation on K8s.
- `argocd_app_sync.sh`: Syncs apps and waits for health/sync status.
- `argocd_list_apps.sh`: Lists all apps and their health status.
</details>

<details id="aws-scripts">
<summary>☁️ AWS Scripts</summary>

- `aws_s3_sync.sh`: Robust S3 synchronization with dry-run support.
- `aws_find_unused_ebs.sh`: Identifies unattached EBS volumes.
- `aws_secret_rotation_check.sh`: Identifies stale or unrotated Secrets Manager secrets.
</details>

<details id="general-utilities">
<summary>🛠️ General Utilities</summary>
- `argocd_app_diff.sh`: Shows diff between Git and Cluster for an app.

- `check_sys_info.sh`: Linux system health and resource summary.
- `check_disk_space.sh`: Monitoring with configurable thresholds.
- `check_ssl_expiry.sh`: Monitors SSL certificate expiration dates.
- `check_zombie_processes.sh`: Detects and reports zombie processes.
- `find_large_files.sh`: Identifies top storage consumers.
- `kill_proc.sh` / `proc_exist_script.sh`: Process management utilities.
- `monitor_process_resources.sh`: Tracks CPU/MEM usage of a specific PID over time.
- `bump_version.sh` / `bump_version_nb.sh`: Automated versioning logic.
- `validate_env_vars.sh`: Ensures required secrets are present.
- `wait_for_url.sh`: Polls endpoints until they return 200 OK.
- `send_slack_notification.sh`: Webhook-integrated Slack alerts.
- `hadolint_scan.sh`: Dockerfile linting via temporary containers.
- `get_helm.sh` / `install_boost.sh`: Tool installation scripts.
- `extract_cmake_project_name.sh`: CMake metadata extraction.
- `auto_completion.sh`: Bash auto-completion setup for DevOps tools.
</details>

---

<h2 id="azure-devops-templates">🏗️ Azure DevOps Templates</h2>

Located in `az_devops_templates/`, these follow a modular design:

- **`common/`**: Step-level templates for security (Gitleaks, Trivy, Xray), docker, and gitflow.
- **`jobs/`**: Parameterized job templates for multi-language builds (.NET, C++, Node.js, Python) and deployments (K8s, VM, Web App).
- **`pipelines/`**: End-to-end examples and maintenance utilities (agent cleanup, compliance scans).

---

<h2 id="performance-bolt">⚡ Performance (Bolt)</h2>

This repository adheres to the **Bolt** philosophy for high-performance automation:

- **Pipeline Consolidation**: Reducing process forks by combining shell operations. For example, using a single `awk` command to replace `grep | cut | sed` chains.
- **Early Exit Logic**: Utilizing `sed -nE '/pattern/ { s/match/replace/p; q }'` to stop file processing immediately after a match, significantly improving performance on large files.
- **O(N+M) Set Operations**: Replacing O(N*M) nested loops with efficient set comparisons using `grep -xvFf` for exact line matching.
- **Git Plumbing**: Using low-level Git commands (e.g., `git rev-parse --abbrev-ref HEAD`, `git diff --name-only --cached`) instead of parsing porcelain output for ~25% faster execution.
- **Native CLI Filtering**: Leveraging `az --query`, `docker inspect --format`, and `jq` for multi-field extraction into variables using `read` and formatted output (TSV).
- **Resource Optimization**: Using `mapfile -t` for robust array-based line processing and replacing `echo | sed` with Bash parameter expansion (e.g., `${VAR//[![:alnum:]]/_}`).

<h2 id="security-sentinel">🛡️ Security (Sentinel)</h2>

The **Sentinel** philosophy ensures all automation is "Secure by Default":

- **Left-Shift Integration**: Security scanners (Gitleaks for secrets, Trivy for containers, Xray for artifacts) are embedded into the earliest stages of every pipeline.
- **Risk Identification**: Scripts are designed to detect critical risks like pods without `PodDisruptionBudgets`, containers running as `root`, and stale IAM accounts.
- **Credential Safety**: Strictly prioritizing environment variables over positional arguments. Scripts use `--password-stdin` for Docker and array-based `curl` arguments `"${ARGS[@]}"` to prevent shell injection and secret leakage.
- **Stealth Logging & Redaction**: Automated check for interactive terminals (`[ -t 1 ]`) to redact sensitive output in CI/CD environments by default, with an optional `--raw` flag for authorized automation.
- **Input Validation**: Robust validation of numeric inputs using `[[ "$VAR" =~ ^[0-9]+$ ]]` before use in shell arithmetic to prevent injection vulnerabilities.

---

<h2 id="contributing">🤝 Contributing</h2>

Contributions are welcome! Please ensure:
1. New scripts follow the `set -euo pipefail` standard.
2. Every script includes a `usage()` function and tool availability checks.
3. Documentation in the relevant sub-README is updated.
4. Changes align with **Bolt** and **Sentinel** principles.

<h2 id="license">📜 License</h2>

MIT - See [LICENSE](./LICENSE) for details. (Made by Kobi Kuzi)
