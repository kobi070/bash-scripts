# general_scripts

This directory contains general-purpose utility scripts for system monitoring, development workflows, and automation.

## 📜 Scripts Overview

### System Monitoring & Info
1. **check_sys_info.sh**
   Provides a detailed summary of CPU, memory, disk usage, and OS details.

2. **check_disk_space.sh**
   Monitors disk usage and returns a non-zero exit code if thresholds are exceeded.

3. **find_large_files.sh**
   Identifies files larger than a specified size in a directory tree.

4. **check_ssl_expiry.sh**
   Checks the expiration date of an SSL certificate for a given domain.

5. **check_zombie_processes.sh**
   Detects zombie processes (status 'Z') on the system.

### Process Management
6. **kill_proc.sh**
   Finds and kills a process by name or port.

7. **proc_exist_script.sh**
   Checks if a specific process is running.

### Development & Automation
8. **bump_version.sh / bump_version_nb.sh**
   Automates version bumping in files (with or without backups).

9. **validate_env_vars.sh**
   Ensures required environment variables are set before proceeding with a task.

10. **wait_for_url.sh**
    Polls a URL until it returns a 200 OK status.

11. **send_slack_notification.sh**
    Sends custom messages to Slack via Webhooks.

12. **auto_completion.sh**
    Configures bash auto-completion for common CLI tools.

### Tools & Installation
13. **hadolint_scan.sh**
    Lints Dockerfiles using Hadolint via a temporary Docker container.

14. **get_helm.sh / install_boost.sh**
    Installation scripts for Helm and Boost libraries.

15. **extract_cmake_project_name.sh**
    Utility to extract the project name from a `CMakeLists.txt` file.

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
