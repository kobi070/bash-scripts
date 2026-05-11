# DevOps Automation Scripts & Templates

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-DevOps-0078D4?logo=azure-devops&logoColor=white)

A comprehensive collection of specialized DevOps scripts and Azure DevOps YAML templates designed to automate installations, configurations, and CI/CD workflows across various environments.

## 🌟 Overview

This repository serves as a centralized hub for automation assets, covering:
- **Cloud Providers**: AWS, Azure
- **Containerization**: Docker, Trivy
- **Orchestration**: Kubernetes, ArgoCD, Minikube
- **Infrastructure as Code**: Terraform
- **Artifact Management**: JFrog Artifactory
- **CI/CD**: Azure DevOps Templates, GitHub API automation
- **Utility**: System monitoring, versioning, and general-purpose Linux scripts

## 📂 Repository Structure

The repository is organized into technology-specific directories:

- [argocd_scripts/](./argocd_scripts/): ArgoCD installation and app management.
- [aws_scripts/](./aws_scripts/): AWS CLI and S3 automation.
- [az_devops_templates/](./az_devops_templates/): Reusable YAML templates for Azure DevOps pipelines.
- [az_scripts/](./az_scripts/): Azure CLI and Azure DevOps automation.
- [docker_scripts/](./docker_scripts/): Docker environment management, image handling, and security scanning.
- [general_scripts/](./general_scripts/): System utilities, versioning, and monitoring.
- [github_scripts/](./github_scripts/): GitHub API and Git workflow automation.
- [jfrog_scripts/](./jfrog_scripts/): JFrog CLI and Artifactory management.
- [k8s_scripts/](./k8s_scripts/): Kubernetes cluster initialization and resource management.
- [terraform_scripts/](./terraform_scripts/): Terraform environment setup and validation.

## 🛠️ Prerequisites

Most scripts require specific CLI tools. Ensure you have the relevant ones installed:
- **Bash**: Most scripts use `set -euo pipefail`.
- **Docker**: Required for `docker_scripts` and `hadolint_scan.sh`.
- **kubectl**: Required for `k8s_scripts` and `argocd_scripts`.
- **Azure CLI (`az`)**: Required for `az_scripts`.
- **AWS CLI (`aws`)**: Required for `aws_scripts`.
- **JFrog CLI (`jf` or `jfrog`)**: Required for `jfrog_scripts`.
- **GitHub CLI (`gh`)** or `curl`/`jq`: Required for `github_scripts`.
- **Terraform**: Required for `terraform_scripts`.
- **jq**: Essential for parsing JSON output from various APIs (GitHub, K8s, Azure).

## 📜 Available Scripts

### ArgoCD Scripts
- `install-argocd.sh`: Installs ArgoCD on your Kubernetes cluster.
- `argocd_app_sync.sh`: Syncs an ArgoCD application and waits for it to be Healthy.
- `argocd_list_apps.sh`: Lists all ArgoCD applications with status.

### Kubernetes Scripts
- `ini_k8s.sh`: Kubernetes initialization script.
- `minikube_install.sh`: Installs Minikube.
- `minikube_start.sh` / `minikube_stop.sh`: Manage Minikube lifecycle.
- `k8s_wait_ready.sh`: Waits for resources to reach a ready state.
- `k8s_decode_secret.sh`: Decodes all keys in a Kubernetes secret.
- `k8s_node_resource_usage.sh`: Summarizes cluster resource usage.

### Docker Scripts
- `install_docker.sh`: Removes old versions and installs the latest Docker.
- `docker_build_push.sh`: Advanced build and push with multi-tag support.
- `trivyScans.sh`: Scans Docker images for vulnerabilities.
- `docker_tag_exists.sh`: Checks remote registry for tags without pulling.
- `docker_clean_unused.sh`: Safely prunes unused Docker resources.

### JFrog Scripts
- `jfrog_config.sh`: Configures JFrog CLI server details.
- `jfrog_upload.sh` / `jfrog_download.sh`: Artifact management using JFrog CLI.
- `jf_xray_scan.sh`: Initiates Xray security scans on artifacts.
- `upload_generic.sh` / `pull_generic.sh`: API-based artifact handling via `curl`.

### Azure Scripts
- `az_devops_config.sh`: Configures Azure DevOps CLI with PAT.
- `az_script_advance.sh`: End-to-end Azure DevOps project and pipeline setup.
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups.

### Terraform Scripts
- `envsetup.sh`: Installs all needed dependencies for Terraform.
- `tf_validate_all.sh`: Recursively validates all Terraform modules in the project.
- `tf_check_fmt.sh`: Ensures Terraform code adheres to canonical format.

### AWS Scripts
- `aws_s3_sync.sh`: Efficiently syncs local directories with S3 buckets.

### GitHub Scripts
- `gh_create_release.sh`: Automates GitHub release creation via API.
- `gh_get_latest_release.sh`: Fetches the latest release tag.
- `commit_script.sh`: Streamlines the add-commit-push workflow.

### Azure DevOps Templates
Located in `az_devops_templates/`, these follow a modular design for maximum reusability:
- **`common/`**: Step-level templates for:
  - `security_scans.yml`: Gitleaks, SonarCloud, Trivy, and JFrog Xray.
  - `docker_build_push.yml`: Standardized Docker workflow with integrated security.
  - `gitflow_logic.yml`: Environment detection based on branch naming.
- **`jobs/`**: Job-level templates:
  - `build_test_job.yml`: Parameterized job supporting .NET, C++, Node.js, and Python.
  - `deploy_k8s_job.yml`: Helm-based deployments to Kubernetes.
  - `deploy_webapp_job.yml`: Azure Web App deployments.
- **`pipelines/`**: End-to-end pipeline examples demonstrating how to compose the above templates.

### General Scripts
- `check_sys_info.sh`: Comprehensive Linux system information.
- `check_disk_space.sh`: Monitoring with configurable warning thresholds.
- `send_slack_notification.sh`: Pipeline notifications via Webhooks.
- `hadolint_scan.sh`: Dockerfile linting via Docker.

## 🚀 Usage

Most scripts can be executed directly after making them executable:

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

For scripts that handle secrets, it is highly recommended to use **Environment Variables** instead of positional arguments to prevent exposure in process lists.

## 🛡️ Security

This repository follows **Sentinel** security principles:
- **Secret Management**: Prefer environment variables over command-line arguments.
- **Left-Shift**: CI/CD templates integrate Gitleaks, Trivy, and Xray by default.
- **Verbose Logging**: Avoid `curl -v` with sensitive headers to prevent credential leakage.

## 📈 Recent Updates

- **Enhanced Azure DevOps**: Added comprehensive YAML templates for multi-language CI/CD.
- **Security Scans**: Integrated Trivy and Hadolint into automation workflows.
- **JFrog Integration**: Expanded scripts for Xray scanning and release management.
- **Utility Improvements**: Added disk monitoring and Slack notification scripts.

## 🤝 Contributing

Feel free to submit pull requests with additional scripts or improvements. Please ensure new scripts follow the guidelines in `AGENTS.md`.

## 📜 License

MIT - See [LICENSE](LICENSE) for details. (All rights reserved, Made by Kobi Kuzi)
