# general_scripts

This directory contains general-purpose utility scripts for system monitoring, development workflows, and automation.

## 📖 Overview
These tools are designed to be portable and easily integrated into various CI/CD pipelines.

## 📜 Scripts Overview

### System Monitoring & Info
1. **check_sys_info.sh**: Detailed summary of CPU, memory, disk usage, and OS details.
2. **check_disk_space.sh**: Monitors disk usage with configurable thresholds.
3. **find_large_files.sh**: Identifies large files in a directory tree.
4. **check_ssl_expiry.sh**: Checks the expiration date of SSL certificates.
5. **check_zombie_processes.sh**: Detects zombie processes on the system.
6. **multi_url_monitor.sh**: Health-checks multiple URLs with optional Slack alerting.
7. **url_health_summary.sh**: Reports status codes and latency for a list of URLs.

### Process Management
8. **kill_proc.sh**: Finds and kills a process by name or port.
9. **proc_exist_script.sh**: Checks if a specific process is running.
10. **check_port_listening.sh**: Verifies if specific ports are listening.
11. **monitor_process_resources.sh**: Tracks CPU and Memory usage of a PID over time.

### Development & Automation
12. **bump_version.sh / bump_version_nb.sh**: Automates version bumping in files.
13. **validate_env_vars.sh**: Ensures required environment variables are set.
14. **wait_for_url.sh**: Polls a URL until it returns a 200 OK status.
15. **send_slack_notification.sh**: Sends custom messages to Slack via Webhooks.
16. **auto_completion.sh**: Configures bash auto-completion for DevOps tools.
17. **check_url_content.sh**: Verifies URL status and body content.

### Tools & Installation
18. **hadolint_scan.sh**: Lints Dockerfiles using Hadolint.
19. **get_helm.sh / install_boost.sh**: Installation scripts for Helm and Boost.
20. **extract_cmake_project_name.sh**: Extracts project name from `CMakeLists.txt`.

## 🚀 Usage

### Check System Info
```bash
./check_sys_info.sh
```

### Monitor Multiple URLs
```bash
./multi_url_monitor.sh https://google.com https://github.com
```

### Send Slack Notification
```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
./send_slack_notification.sh "Build successful!"
```

### Monitor Process
```bash
./monitor_process_resources.sh <pid> 60 5
```

## ✅ Prerequisites

- Bash shell.
- `curl` and `jq` for networking and JSON scripts.
- `docker` for `hadolint_scan.sh`.

## 📘 Notes
- These scripts are designed to be portable across Linux environments.
