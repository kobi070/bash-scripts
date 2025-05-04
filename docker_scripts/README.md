# docker_scripts

This repository contains a collection of shell scripts to help manage Docker environments efficiently. These scripts cover installation, cleanup, image tagging, pushing to repositories, and more.

## 📜 Scripts Overview

1. **check_docker.sh**  
   Verifies if Docker is installed and running on the system.

2. **clean_docker_images.sh**  
   Removes unused Docker images to free up disk space.

3. **clean_docker_ps.sh**  
   Cleans up stopped containers.

4. **docker_login.sh**  
   Logs into a Docker registry using provided credentials.

5. **docker_push_to_repo.sh**  
   Pushes a Docker image to a specified repository.

6. **docker-net-prune.sh**  
   Removes all unused Docker networks.

7. **docker-tag-push-from-file.sh**  
   Tags and pushes Docker images based on input from a file.

8. **docker-tag-push.sh**  
   Tags and pushes a Docker image to a repository.

9. **docker-vol-prune.sh**  
   Removes all unused Docker volumes.

10. **install_docker.sh**  
    Installs Docker on the system.

## 🚀 Usage

To run any script, use the following command in your terminal:

```bash
./script_name.sh
```

Replace script_name with the name of the script you want to execute (e.g., install_docker, docker_push_to_repo, etc.).

✅ Prerequisites

- Bash shell must be available on your system.
- For most scripts, Docker must be installed and configured.
- For pushing images, ensure you are logged into the appropriate Docker registry.
📘 Notes
- Always review scripts before running them, especially those that prune or delete resources.
- For more information on Docker CLI commands, visit the official Docker documentation.
