# ⚡ DevOps Automation Hub 🛡️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-DevOps-0078D4?logo=azure-devops&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-623CE4?logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-2088FF?logo=github-actions&logoColor=white)

A high-performance, security-focused collection of specialized DevOps scripts and Azure DevOps YAML templates designed to automate installations, cloud configurations, and complex CI/CD workflows.

---

## 📑 Table of Contents

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
| **JFrog CLI** | For `jfrog_scripts` (`jf` or `jfrog`). |
| **Terraform** | For `terraform_scripts`. |

<h2 id="environment-variables">🔐 Environment Variables</h2>

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

2. **Run a system health check**:
   ```bash
   ./general_scripts/check_sys_info.sh
   ```

3. **Initialize a Kubernetes environment**:
   ```bash
   ./k8s_scripts/init_k8s.sh
   ```

4. **Trigger an Azure DevOps Pipeline**:
   ```bash
   ./az_scripts/az_devops_run_pipeline.sh --name "Production-Deploy"
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

MIT - See [LICENSE](LICENSE) for details. (All rights reserved, Made by Kobi Kuzi)
