# Bolt's Journal - Performance Learnings

## 2025-05-15 - [Process reduction in shell scripts]
**Learning:** Pipelines like `grep | head | sed` incur significant overhead due to multiple process forks. A single `sed` command with the `q` (quit) instruction can achieve the same result more efficiently by reducing forking and stopping file processing immediately after a match is found.
**Action:** Use single-tool solutions (like `sed` or `awk`) instead of multi-process pipelines for simple text extraction tasks.

## 2026-05-13 - [Git plumbing for branch and status]
**Learning:** Parsing Git porcelain output (e.g., `git branch`, `git status`) with shell pipelines (`grep`, `awk`, `cut`) is slow due to process forking and fragile with complex filenames. Git plumbing commands like `git rev-parse --abbrev-ref HEAD` and `git diff --name-only --cached` are faster and designed for scripting.
**Action:** Use Git plumbing commands instead of parsing command output for branch detection and file listing in automation scripts.

## 2026-05-14 - [Native CLI querying for multi-field extraction]
**Learning:** Parsing JSON output with multiple `grep` or `jq` calls in succession is inefficient as each call forks a new process. Tools like the Azure CLI (`az`) provide native querying capabilities (e.g., `--query` with JMESPath) that can extract multiple fields into a tab-separated format in a single pass. Combining this with the Bash `read` builtin can reduce process forks by 3-4 per script execution.
**Action:** Prefer native CLI querying parameters (like `az --query` or `docker inspect --format`) over multiple shell pipes for extracting multiple data points from the same command.
