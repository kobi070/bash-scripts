## 2025-05-14 - Leakage of API Keys in Verbose Logs
**Vulnerability:** Use of `curl -v` with sensitive headers (`X-JFrog-Art-Api: $JFROG_API_KEY`) exposes the API key in the standard error output.
**Learning:** Verbose output in `curl` includes request headers. If these headers contain secrets, they will be printed to logs, which is a security risk in CI/CD environments or shared systems.
**Prevention:** Avoid using verbose mode (`-v`, `--verbose`) in production scripts when handling secrets. Use specific `curl` options to debug if needed, or rely on exit codes and structured error messages.

## 2025-05-15 - Secret Exposure in Process Lists via Positional Arguments
**Vulnerability:** Passing passwords, tokens, or API keys as command-line arguments (e.g., `./script.sh <secret>`) makes them visible to all users on the system via `ps` or `/proc` and often records them in shell history files.
**Learning:** Many scripts in this repository were initially designed to take secrets as positional arguments for simplicity, creating a significant security gap.
**Prevention:** Prioritize environment variables for all secrets. If positional arguments must be supported for backward compatibility, implement a security warning and encourage the use of environment variables instead.

## 2025-05-16 - PAT Exposure in Git Configuration via URLs
**Vulnerability:** Embedding Personal Access Tokens (PAT) directly in Git remote URLs (e.g., `https://<pat>@dev.azure.com/...`) causes Git to store the token in plaintext within the `.git/config` file.
**Learning:** This exposure persists even after the script finishes, as the remote URL is a persistent part of the repository configuration. Anyone with access to the local repository folder can retrieve the PAT.
**Prevention:** Use `git -c http.extraheader="Authorization: Basic <base64-pat>"` for Git operations to provide authentication for a single command without storing it in the repository configuration. Always prefer environment variables for passing the PAT to the script.

## 2025-05-17 - Accidental Secret Leakage in Non-Interactive Logs
**Vulnerability:** Decoded Kubernetes secrets are printed directly to stdout, which can be captured in CI/CD logs or persistent shell history if redirected.
**Learning:** DevOps utility scripts are often used in both interactive debugging and non-interactive CI/CD contexts. Without checking the terminal type, sensitive data is indiscriminately logged in persistent storage.
**Prevention:** Implement a check for an interactive terminal (`[ -t 1 ]`) before printing sensitive data. Redact secrets by default in non-interactive modes, providing an explicit override flag (e.g., `--raw`) for authorized automated extraction.

## 2025-05-17 - Shell Arithmetic Injection via Unvalidated Numeric Input
**Vulnerability:** User-supplied inputs used in Bash arithmetic contexts (`$((...))`, `((...))`, or `[[ $val -gt 0 ]]`) allow arbitrary command execution if the input contains malicious payloads like `1+RANDOM[$(command)]0`.
**Learning:** Bash evaluates variables within arithmetic expressions. If a variable contains a specially crafted string, it can trigger command substitution during evaluation, even if the variable is not explicitly preceded by `$`.
**Prevention:** Always validate that inputs intended for numeric use contain only digits using a regex check `[[ "$VAR" =~ ^[0-9]+$ ]]` before they are used in any arithmetic comparison or expansion.

## 2026-05-21 - Shell Arithmetic Injection via Double Brackets
**Vulnerability:** Even with quoted variables, Bash's double brackets `[[ $VAR -gt 0 ]]` still perform arithmetic evaluation on the content of `$VAR`, allowing command execution via payloads like `a[$(touch file)]`.
**Learning:** The behavior of `[[ ]]` for numeric comparisons is more permissive/dangerous than `[ ]` (test). While `[ "$VAR" -gt 0 ]` fails with an "integer expression expected" error for malicious strings, `[[ "$VAR" -gt 0 ]]` evaluates the expression within the brackets.
**Prevention:** Always use a strict regex check `[[ "$VAR" =~ ^[0-9]+$ ]]` before using ANY variable in a numeric comparison, even when using `[[ ]]` or quoting variables.

## 2026-05-18 - Kubernetes Availability and Container Security Audits
**Vulnerability:** Workloads running without PodDisruptionBudgets (PDB) are at risk of downtime during node maintenance. Running containers as root increases the blast radius of a container escape.
**Learning:** Correlating Kubernetes resources (Deployments/PDBs) in shell scripts is most efficient when fetching both as JSON and using `jq` for label matching, rather than multiple `kubectl` calls.
**Prevention:** Implement automated PDB auditing and container root-check scripts to "left-shift" these availability and security checks.

## 2026-05-19 - GITHUB_TOKEN Exposure in Process List via curl Headers
**Vulnerability:** Using `curl -H "Authorization: token $GITHUB_TOKEN"` exposes the sensitive token in the system's process list (visible via `ps`), making it accessible to other users or logging tools on the same host.
**Learning:** While environment variables are safer than positional arguments, passing them as command-line flags to external binaries still leaks them into the process table.
**Prevention:** Use `curl`'s `--config -` (or `-K-`) flag to pass sensitive headers via standard input. By piping the header string directly to `curl`, the secret never appears in the command-line arguments.

## 2026-05-22 - Slack Webhook URL Exposure and curl Config Escaping
**Vulnerability:** Passing Slack Webhook URLs (which contain secrets) or sensitive JSON payloads as command-line arguments to `curl` exposes them in system process lists.
**Learning:** Using `curl -K-` to pass the URL and data via stdin is effective, but requires careful handling of the `curl` config format. Specifically, the `data` parameter value must be a single line (unless escaped) and requires backslashes and double quotes to be escaped (e.g., `\\` and `\"`) to prevent the `curl` parser from misinterpreting them or failing on newlines.
**Prevention:** Always use `jq -c` to generate compact, single-line JSON payloads and use `sed 's/\\/\\\\/g; s/"/\\"/g'` to robustly escape them before passing to `curl -K-` via stdin.

## 2026-05-23 - Robust API Error Handling with jq
**Vulnerability:** Fragile error handling when parsing API responses can lead to script failures or bypassed security checks if the JSON structure changes between success (e.g., an array) and error (an object).
**Learning:** GitHub list APIs return an array on success. Attempting to check for an error field like `.message` using `jq` on an array results in a fatal error: `Cannot index array with string "message"`.
**Prevention:** Use the optional indexing operator `?` in `jq` (e.g., `jq -e '.message?'`) to safely probe for error fields. This allows the same check to work whether the response is an error object or a successful array of items, ensuring consistent error detection.

## 2025-05-24 - Secret Exposure in Process Lists via JFrog CLI Flags
**Vulnerability:** Passing passwords or tokens to the JFrog CLI using the `--password` flag (e.g., `jf c add ... --password=$PASS`) makes them visible to all users on the system via process monitoring tools like `ps`.
**Learning:** Many CLI tools provide command-line flags for authentication for convenience, but these are insecure for non-interactive use in shared environments or CI/CD runners.
**Prevention:** Always prioritize using environment variables supported by the CLI (e.g., `JFROG_CLI_PASSWORD`) for sensitive information. Explicitly unset or avoid passing these secrets as command-line arguments.
## 2026-05-28 - JFrog CLI Password Exposure in Process List
**Vulnerability:** Passing the Artifactory password or token using the `--password` flag to the JFrog CLI (`jf c add`) exposes it in the system's process list (visible via `ps`).
**Learning:** Unlike `curl`, the JFrog CLI does not support a "config file via stdin" pattern for all its commands. However, it respects specific environment variables like `JFROG_CLI_PASSWORD` for authentication during configuration.
**Prevention:** Prioritize using the `JFROG_CLI_PASSWORD` environment variable when configuring the JFrog CLI. Avoid passing secrets via the `--password` flag to prevent leakage into the process table.

## 2026-05-30 - Command Execution via Unintended Subshell Syntax
**Vulnerability:** Using `$(variable)` instead of `${variable}` in `echo` or other commands causes Bash to attempt to execute the value of the variable as a command.
**Learning:** This is a common typo that results in an unintended subshell. If the variable's value (e.g., a version string parsed from a file) can be influenced by an untrusted source, it leads to arbitrary command execution.
**Prevention:** Strictly use `${variable}` or `$variable` for variable expansion. Avoid the `$(...)` syntax unless command substitution is explicitly intended. Regularly audit scripts for this pattern, especially in log/echo statements.

## 2026-06-01 - Argument Injection via Unquoted Optional Flags
**Vulnerability:** Passing optional flags to CLI tools using unquoted variables (e.g., `kubectl logs $TAIL_ARG`) allows for argument injection or unintended word splitting if the variable contains spaces or multiple arguments.
**Learning:** Even if the variable is constructed safely in the script, using it unquoted during expansion is a weak point. If the input validation is bypassed or incomplete, it can lead to command or argument injection.
**Prevention:** Use shell arrays to store optional arguments (e.g., `ARGS=("--flag=$VAL")`) and expand them using quoted array syntax `"${ARGS[@]}"`. This ensures that each element of the array is treated as a single word, preventing injection and correctly handling cases where no arguments are provided. Always combine this with strict input validation.
## 2026-06-01 - Command Injection via Indirect Expansion
**Vulnerability:** Bash's indirect expansion `${!VAR_NAME}` evaluates array indices within the variable name. If `VAR_NAME` is user-controlled and contains a payload like `arr[$(command)]`, the command will be executed during expansion.
**Learning:** Indirect expansion is a powerful feature often used for dynamic variable access (e.g., in validation loops), but it is a sink for command injection if the variable name itself is not sanitized.
**Prevention:** Always validate that the variable name used for indirect expansion is a valid shell identifier using a strict whitelist regex: `[[ "$VAR_NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]`.
## 2025-06-05 - Command Injection via Indirect Variable Expansion
**Vulnerability:** Using Bash indirect expansion `${!VAR_NAME}` on untrusted input allows arbitrary command execution if the input contains array index syntax with command substitution (e.g., `VAR[$(command)]`).
**Learning:** Bash evaluates the content of the variable name in an arithmetic context if it looks like an array reference, even during indirect expansion. This can be exploited to execute commands.
**Prevention:** Always validate that the variable name string matches a strict whitelist (e.g., `^[a-zA-Z_][a-zA-Z0-9_]*$`) before using it in an indirect expansion `${!VAR_NAME}`.
## 2025-07-01 - Argument Injection in curl via Hyphenated URLs
**Vulnerability:** URLs starting with a hyphen (e.g., `-V`) passed to `curl` without a separator are interpreted as command-line options, leading to argument injection.
**Learning:** Even if a variable is quoted, shell commands like `curl` that parse options before positional arguments can be tricked if the variable's value starts with a dash.
**Prevention:** Always use the `--` separator to explicitly mark the end of options and the beginning of positional arguments when passing user-supplied variables to commands like `curl`, `grep`, or `sed`.
