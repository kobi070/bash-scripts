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

## 2025-05-18 - Secret Exposure in Process Lists via Curl Headers
**Vulnerability:** Passing sensitive headers to `curl` using the `-H` flag (e.g., `-H "Authorization: token $TOKEN"`) makes the secrets visible in the system's process list (via `ps` or `/proc`) during the entire duration of the network request.
**Learning:** Even when scripts correctly use environment variables, the final call to a CLI tool can re-expose those secrets if they are passed as command-line arguments.
**Prevention:** Use `curl`'s `--config -` (or `-K-`) option to pass sensitive headers via standard input. Using `printf` (a shell builtin) to pipe the configuration ensures the secret is never part of an `argv` array for an external process.
