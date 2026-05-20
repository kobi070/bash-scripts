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

5. **gh_list_merged_pr_authors.sh**
   Lists unique authors of merged pull requests within a specified date range.

### PR & Workflow Analysis
6. **gh_workflow_stats.sh**
   Summarizes GitHub Action workflow run statuses for a repository.

7. **gh_workflow_failure_logs.sh**
   Fetches and displays logs of the most recent failed GitHub workflow run.

8. **gh_pr_size_checker.sh**
   Categorizes open PRs by size (XS to XL) based on total lines of code changed.

9. **gh_pr_stats.sh**
   Calculates average time-to-merge and detailed stats for the last N pull requests.

10. **gh_list_collaborators.sh**
   Lists all collaborators of a GitHub repository using the GitHub API.

### Repository Management
11. **init_repo.sh**
   Initializes a new Git repository with a default `main` branch.

12. **commit_script.sh / commit_script_no_push.sh**
   Simplifies the workflow of adding, committing, and optionally pushing changes.

13. **logs_script.sh**
   Displays formatted Git logs for better readability.

### Git Configuration & Utilities
14. **create_command_alias.sh / check_alias.sh**
   Utilities for managing and verifying Git aliases.

15. **git_cleanup_merged_branches.sh**
    Deletes local branches that have already been merged into the default branch.

16. **gh_repo_compliance_audit.sh**
    Audits GitHub repository settings (visibility, branch protection) against best practices.

## 🚀 Usage
### Create a Release
```bash
export GITHUB_TOKEN="your_token"
./gh_create_release.sh --tag "v1.2.3" --name "Release v1.2.3"
```

### Simplify Commits
```bash
./commit_script.sh "docs: improve readme"
```

### Fetch Failed Workflow Logs
```bash
export GITHUB_TOKEN="your_token"
./gh_workflow_failure_logs.sh octocat/hello-world ci.yml
```

### Check PR Sizes
```bash
./gh_pr_size_checker.sh kubernetes/kubernetes
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
