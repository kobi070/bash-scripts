# general_scripts

This repository contains a variety of general-purpose shell scripts designed to assist with system management, versioning, and development tool setup.

## 📜 Scripts Overview

1. **auto_completion.sh**  
   Sets up shell auto-completion for supported commands or scripts.

2. **bump_version_nb.sh**  
   Increments a version number (non-breaking) in a specified format or file.

3. **bump_version.sh**  
   Increments a version number, potentially including breaking changes or major version updates.

4. **check_sys_info.sh**  
   Displays system information such as OS details, CPU, memory, and disk usage.

5. **get_helm.sh**  
   Downloads and installs Helm, the Kubernetes package manager.

6. **kill_proc.sh**  
   Kills a process by name or PID.

7. **proc_exist_script.sh**  
   Checks if a specific process is currently running.

## 🚀 Usage

To run any script, use the following command in your terminal:

```bash
./script_name.sh
```

Replace script_name with the name of the script you want to execute (e.g., check_sys_info, bump_version, etc.).

✅ Prerequisites

- Bash shell must be available on your system.
- Some scripts may require elevated privileges (e.g., kill_proc.sh).
- Internet access may be required for scripts like get_helm.sh.
📘 Notes
- Always review scripts before executing them to ensure they meet your system's requirements.
- For more information on Helm, visit the official Helm documentation.
