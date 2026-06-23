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

## 2026-05-15 - [Bash built-ins for string manipulation]
**Learning:** External processes like `sed`, `cut`, and `tr` are often used for simple string sanitization and transformation, but they incur process fork overhead. Bash parameter expansion (`${VAR//search/replace}`, `${VAR#prefix}`, `${VAR%suffix}`) is executed directly by the shell and is significantly faster for these tasks.
**Action:** Use Bash parameter expansion instead of piping to `sed` or `cut` for basic string manipulation in performance-critical or frequently executed scripts.

## 2026-05-16 - [Set difference with grep -xvFf]
**Learning:** Using `grep -vFf` to find the difference between two sets of data (e.g., finding unused resources) is significantly faster than a nested loop but can introduce bugs. Without `-x`, it performs substring matching, which can cause false positives (e.g., 'pvc1' matching 'pvc11'). Additionally, if the pattern file/input is empty, `grep` may match all lines or none depending on the implementation and input, often requiring an explicit check for empty sets.
**Action:** Always use the `-x` flag for exact line matching and implement a check to ensure the pattern set is not empty before executing `grep` in set difference operations.
## 2026-05-16 - [Consolidated Docker inspection]
**Learning:** Checking container status with `docker ps | grep` before retrieving metadata with `docker inspect` adds multiple unnecessary process forks. `docker inspect` itself can report both the container's state (running/stopped) and its network properties in a single execution using Go templates.
**Action:** Consolidate existence/status checks and data extraction into a single `docker inspect` or `docker container inspect` call when possible.
## 2026-05-18 - High-Performance Workflow Analytics and IAM Audits
**Learning:** In `jq`, performing numeric calculations (like date differences) can lose the object context. Assigning fields to variables (e.g., `.AccessKeyId as $id`) before the calculation ensures they remain accessible for the final output string, avoiding "Cannot index number with string" errors.
**Action:** Consistently use `jq` variables for field extraction in scripts involving multi-stage JSON transformations.

## 2026-05-19 - [jq Operator Precedence with Variable Assignment]
**Learning:** In `jq`, the division operator (`/`) has higher precedence than variable assignment (`as`). Attempting a calculation like `A - B / 3600 as $h` results in `jq` trying to divide `B` by the string `"as $h ..."`, leading to a type error. Parenthesizing the entire calculation is required.
**Action:** Always parenthesize complex calculations in `jq` filters before assigning the result to a variable: `((.mergedAt | fromdateiso8601) - (.createdAt | fromdateiso8601)) / 3600 as $diff_hours`.

## 2026-05-20 - [O(N) to O(1) AWS IAM Auditing]
**Learning:** Auditing IAM user activity using loops of `aws iam get-user` or `list-access-keys` is highly inefficient and prone to rate limiting as it scales with the number of users ($O(N)$ API calls). The AWS Credential Report provides a comprehensive snapshot of all users and their credential usage in a single CSV artifact, enabling $O(1)$ network complexity for account-wide audits.
**Action:** Use `aws iam generate-credential-report` followed by `aws iam get-credential-report` and `awk` for high-performance IAM activity reporting.

## 2026-05-21 - [O(N) to O(1 + N_stale) AWS IAM Key Age Audit]
**Learning:** Transitioning from a per-user API call pattern ($O(N)$) to using the bulk AWS Credential Report for initial filtering significantly reduces network overhead and latency. By identifying only "candidate" users with potentially stale keys via local processing ($O(1)$), subsequent detailed API calls are minimized to $O(N_{stale})$.
**Action:** Always leverage bulk reporting APIs (like AWS Credential Report or Azure Resource Graph) for account-wide inventory and audit tasks before falling back to individual resource queries.

## 2024-05-22 - [O(N*M) to O(N+M) set subtraction in Kubernetes audits]
**Learning:** Shell scripts frequently use `while read` loops with internal `grep` to find differences between sets (e.g., finding unused resources). This pattern incurs $O(N)$ process forks and $O(N \times M)$ complexity. Standard utilities like `comm -23` (on sorted inputs) or `grep -xvFf` (with process substitution) achieve $O(N + M)$ complexity with constant process overhead.
**Action:** Replace resource-intensive loops with set-based operations using `comm` or `grep -xvFf` for inventory and audit scripts.

## 2026-05-23 - [O(N*M) to O(1) AWS Security Group Audit]
**Learning:** Auditing AWS Security Groups by iterating over groups and then over rules in Bash, while calling `jq` for each rule, creates a massive performance bottleneck due to process fork overhead ($O(N \times M)$). Consolidating the entire filtering and formatting logic into a single `jq` pipeline reduces forks to $O(1)$ and provides a ~20x speedup in moderately sized environments.
**Action:** Use `jq` to handle nested collection processing and formatting entirely, passing the results to Bash via a single `while read` loop with a tab-delimiter.

## 2026-05-24 - [O(N) to O(1) Kubernetes Ingress Audit]
**Learning:** Auditing Ingress resources by calling `jq`, `paste`, and `sort` for each item in a shell loop creates significant process overhead ($O(N)$ forks). Consolidating the extraction of hosts, TLS status, and unique backends into a single `jq` pipeline reduces forks to $O(1)$ and eliminates the need for `paste` and `sort` within the loop.
**Action:** Consolidate multi-field extraction and list manipulation (joining, sorting, uniqueness) into a single `jq` pass for resource-heavy audit scripts.

## 2026-05-25 - [O(N) to O(1) GitHub Branch Audit]
**Learning:** Moving date arithmetic and staleness filtering from a shell loop into a single `jq` pipeline using `fromdateiso8601` reduces process forks from $O(N)$ to $O(1)$. Furthermore, using `jq` for date parsing eliminates the need for platform-specific `date` command variations (GNU vs. BSD), improving script portability and performance (~5x speedup for 100 branches).
**Action:** Use `jq` built-in date functions for all API-driven date calculations to ensure cross-platform compatibility and minimize process overhead.
## 2026-05-25 - [O(N) to O(1) GitHub Stale Branch Audit]
**Learning:** Consolidating GraphQL response processing, date parsing (`fromdateiso8601`), and staleness calculations into a single `jq` pipeline significantly improves performance by eliminating $O(N)$ process forks of `jq` and `date`.
**Action:** Use `jq`'s built-in date functions (`now`, `fromdateiso8601`) to perform time-based filtering on API results in a single pass.

## 2026-05-27 - [O(N*M) to O(1) AWS Resource Tag Audit]
**Learning:** Auditing mandatory tags on cloud resources by iterating over each resource and then each tag in Bash with internal `jq` calls is extremely inefficient ($O(N \times M)$ process forks). Consolidating the tag presence check into a single `jq` pipeline by pre-calculating the target JSON array once and passing it via `--argjson` and the `any()` function reduces the overhead to $O(1)$ process forks for the entire resource set.
**Action:** Use `jq` with `--argjson` to pass mandatory requirements (like tags or labels) and perform bulk validation within a single JSON processing stream.

## 2024-05-30 - [O(N) to O(1) process forks in K8s Secret Audit]
**Learning:** Consolidating multiple 'jq' calls and eliminating per-iteration 'date' command forks significantly improves performance in resource audits. However, relying on OpenSSL 3.0 specific flags like '-dateopt iso_8601' breaks compatibility in older environments. Standard OpenSSL date formats can be parsed portably within 'jq' using 'strptime("%b %e %H:%M:%S %Y %Z") | mktime', where '%e' correctly handles the leading space in single-digit days.
**Action:** Use 'jq' stream processing for data transformation and avoid OpenSSL 3.0+ specific output flags to maintain broad compatibility across Linux and macOS environments.

## 2026-06-23 - [O(N) to O(1) process forks in Kubernetes Pod Drain Audit]
**Learning:** Consolidating iterative shell checks (e.g., calling `jq`, `wc`, or `grep` for each item in a loop) into a single `jq` pipeline significantly reduces process fork overhead and improves script performance. Additionally, passing external JSON data into `jq` via `--argjson` allows for complex, multi-resource correlation (like matching Pods to PDBs via label selectors) entirely within the JSON processor.
**Action:** Replace `while read` loops that contain internal command forks with bulk `jq` processing and use `--argjson` to pass required reference data for cross-resource lookups.
