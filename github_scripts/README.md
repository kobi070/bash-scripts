# github_scripts

This directory contains scripts for automating **GitHub** workflows and interacting with the GitHub API.

## 📜 Scripts Overview

1. **gh_create_release.sh**
   Creates a new GitHub release using the API. Requires `GITHUB_TOKEN`.

2. **gh_get_latest_release.sh**
   Fetches the tag name of the latest release for a repository.

3. **gh_download_release_asset.sh**
   Downloads a specific asset from the latest GitHub release.

4. **gh_list_pull_requests.sh**
   Lists open pull requests for a given repository.

5. **commit_script.sh / commit_script_no_push.sh**
   Simplifies the workflow of adding, committing, and optionally pushing changes.

6. **init_repo.sh**
   Initializes a new Git repository with a default `main` branch.

7. **create_command_alias.sh / check_alias.sh**
   Utilities for managing Git aliases.

8. **logs_script.sh**
   Displays formatted Git logs for better readability.

9. **gh_delete_old_workflow_runs.sh**
   Deletes GitHub Actions workflow runs older than a specified number of days.

## 🚀 Usage

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

✅ Prerequisites

- Git installed and configured.
- `curl` and `jq` installed.
- `GITHUB_TOKEN` environment variable for API-based scripts.

📘 Notes
- API scripts prefer `curl` and `jq` over the `gh` CLI for better portability in CI environments.
