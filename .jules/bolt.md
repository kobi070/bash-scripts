# Bolt's Journal - Performance Learnings

## 2025-05-15 - [Process reduction in shell scripts]
**Learning:** Pipelines like `grep | head | sed` incur significant overhead due to multiple process forks. A single `sed` command with the `q` (quit) instruction can achieve the same result more efficiently by reducing forking and stopping file processing immediately after a match is found.
**Action:** Use single-tool solutions (like `sed` or `awk`) instead of multi-process pipelines for simple text extraction tasks.
