# github_scripts

This directory contains scripts for automating **GitHub** workflows and interacting with the GitHub API.
## 📖 Overview
This directory contains scripts for automating **GitHub** workflows and interacting with the GitHub API. It includes tools for release management, repository initialization, and PR monitoring.

## 📜 Scripts Overview

### GitHub API Automation
1. **gh_create_release.sh**
   Creates a new GitHub release using the API. Requires `GITHUB_TOKEN`.

2. **gh_get_latest_release.sh**
   Fetches the tag name of the latest release for a repository.

3. **gh_download_release_asset.sh**
   Downloads a specific asset from the latest GitHub release.

4. **gh_list_pull_requests.sh**
   Lists open pull requests for a given repository with their status.

### Repository Management
5. **init_repo.sh**
   Initializes a new Git repository with a default `main` branch.

6. **commit_script.sh / commit_script_no_push.sh**
   Simplifies the workflow of adding, committing, and optionally pushing changes.
5. **gh_list_collaborators.sh**
   Lists all collaborators of a GitHub repository using the GitHub API.

6. **gh_pr_stats.sh**
   Calculates average time-to-merge and detailed stats for the last N pull requests.

### Repository Management
6. **init_repo.sh**
   Initializes a new Git repository with a default `main` branch.

7. **commit_script.sh / commit_script_no_push.sh**
   Simplifies the workflow of adding, committing, and optionally pushing changes.

8. **logs_script.sh**
   Displays formatted Git logs for better readability.

### Git Configuration & Utilities
9. **create_command_alias.sh / check_alias.sh**
   Utilities for managing and verifying Git aliases.

10. **gh_workflow_stats.sh**
    Analyzes recent GitHub Actions workflow runs for success rate and duration.

7. **logs_script.sh**
   Displays formatted Git logs for better readability.

### Git Configuration & Utilities
8. **create_command_alias.sh / check_alias.sh**
   Utilities for managing and verifying Git aliases.

## 🚀 Usage
### Create a Release
```bash
export GITHUB_TOKEN="your_token"
./gh_create_release.sh --tag "v1.2.3" --name "Release v1.2.3"
```

### Simplify Commits
```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

✅ Prerequisites

- Git installed and configured.
- `curl` and `jq` installed.
- `GITHUB_TOKEN` environment variable for API-based scripts.

📘 Notes
./commit_script.sh "docs: improve readme"
```

### Pull Request Statistics
```bash
./gh_pr_stats.sh [repo] [limit]
```

## ✅ Prerequisites

- Git installed and configured.
- `curl` and `jq` installed.
- `GITHUB_TOKEN` environment variable for API-based scripts.

## 📘 Notes
- API scripts prefer `curl` and `jq` over the `gh` CLI for better portability in CI environments.
