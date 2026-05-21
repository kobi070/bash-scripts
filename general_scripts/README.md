# general_scripts

## 📖 Overview
This directory contains general-purpose utility scripts for system monitoring, development workflows, and automation. These tools are designed to be portable and easily integrated into various CI/CD pipelines.

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

5. **check_system_entropy.sh**
   Monitors system entropy levels to ensure cryptographic reliability.

6. **check_zombie_processes.sh**
   Detects zombie processes (status 'Z') on the system.

### Health Checks & URL Monitoring
7. **multi_url_monitor.sh**
   Health-checks multiple URLs and provides a status summary, with optional Slack alerting.

8. **wait_for_url.sh**
   Polls a URL until it returns a 200 OK status.

9. **url_health_summary.sh**
   Reports status codes and latency for a list of URLs.

10. **check_url_content.sh**
    Verifies if a URL returns a specific string in its body.

### Process Management
11. **kill_proc.sh**
    Finds and kills a process by name or port.

12. **proc_exist_script.sh**
    Checks if a specific process is running.

13. **check_port_listening.sh**
    Verifies if a specific list of ports is listening on localhost.

14. **monitor_process_resources.sh**
    Monitors CPU and Memory usage of a specific PID over time.

### Development & Automation
15. **bump_version.sh / bump_version_nb.sh**
    Automates version bumping in files (with or without backups).

16. **validate_env_vars.sh**
    Ensures required environment variables are set before proceeding with a task.

17. **send_slack_notification.sh**
    Sends custom messages to Slack via Webhooks.

18. **auto_completion.sh**
    Configures bash auto-completion for common CLI tools.

### Tools & Installation
19. **hadolint_scan.sh**
    Lints Dockerfiles using Hadolint via a temporary Docker container.

20. **get_helm.sh / install_boost.sh**
    Installation scripts for Helm and Boost libraries.

21. **extract_cmake_project_name.sh**
    Utility to extract the project name from a `CMakeLists.txt` file.

## 🚀 Usage

### Check System Info
```bash
./check_sys_info.sh
```

### Monitor Multiple URLs
```bash
./multi_url_monitor.sh https://google.com https://github.com
```

### Monitor Process Resources
```bash
./monitor_process_resources.sh <pid> 60 5
```

### Send Slack Notification
```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
./send_slack_notification.sh "Build successful!"
```

## ✅ Prerequisites

- Bash shell.
- Specific tools as required by individual scripts (e.g., `curl`, `jq`, `docker`).

## 📘 Notes
- These scripts are designed to be portable and can be easily integrated into CI/CD pipelines.
