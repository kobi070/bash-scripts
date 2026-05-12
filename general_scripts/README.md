# general_scripts

This directory contains general-purpose utility scripts for system monitoring, development workflows, and automation.

## 📜 Scripts Overview

### System Monitoring
1. **check_sys_info.sh**
   Provides a detailed summary of CPU, memory, disk usage, and OS details.

2. **check_disk_space.sh**
   Monitors disk usage and returns a non-zero exit code if thresholds are exceeded.

3. **find_large_files.sh**
   Identifies files larger than a specified size in a directory tree.

### Development Utilities
4. **bump_version.sh / bump_version_nb.sh**
   Automates version bumping in files (with or without backups).

5. **validate_env_vars.sh**
   Ensures required environment variables are set before proceeding with a task.

6. **wait_for_url.sh**
   Polls a URL until it returns a 200 OK status.

7. **send_slack_notification.sh**
   Sends custom messages to Slack via Webhooks.

### Tools & Linting
8. **hadolint_scan.sh**
   Lints Dockerfiles using Hadolint via a temporary Docker container.

9. **get_helm.sh / install_boost.sh**
   Installation scripts for Helm and Boost libraries.

10. **extract_cmake_project_name.sh**
    Utility to extract the project name from a `CMakeLists.txt` file.

11. **backup_dir.sh**
    Creates a timestamped compressed backup of a directory with basic rotation logic.

## 🚀 Usage

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

✅ Prerequisites

- Bash shell.
- Specific tools as required by individual scripts (e.g., `curl`, `jq`, `docker`).

📘 Notes
- These scripts are designed to be portable and can be easily integrated into CI/CD pipelines.
