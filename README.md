# Bash Scripts

A collection of utility scripts for automating installations and configurations across different environments.

## Repository Structure

This repository contains scripts organized into the following categories:

- **argocd_scripts**: Scripts for installing and configuring ArgoCD on Kubernetes
- **docker_scripts**: Docker-related automation scripts
- **k8s_scripts**: Kubernetes installation and configuration utilities
- **terraform_scripts**: Scripts for automating Terraform installations and dependencies
- **az_scripts**: Scripts for automating Azure installations and etc
- **aws_scripts**: AWS CLI automation scripts
- **jfrog_scripts**: JFrog CLI and Artifactory automation scripts
- **general_scripts**: Scripts for general use cases
- **github_scripts**: Scripts for general use cases in Github repositories

## Available Scripts

### ArgoCD Scripts

- `install-argocd.sh`: Installs ArgoCD on your own Kubernetes cluster
- `argocd_app_sync.sh`: Syncs an ArgoCD application and waits for it to be Healthy and Synced
- `argocd_list_apps.sh`: Lists all ArgoCD applications with their health and sync status

### Kubernetes Scripts

- `ini_k8s.sh`: Kubernetes initialization script (recently fixed)
- `minikube_status.sh`: Minikube status script
- `minikube_start.sh`: Starts minikube
- `minikube_stop.sh`: Stops minikube
- `minikube_install.sh`: Installs minikube if its not installed yet, you need to have docker installed for this to work
- `k8s_wait_ready.sh`: Waits for a Kubernetes resource (deployment, statefulset, daemonset) to reach a ready state
- `k8s_decode_secret.sh`: Decodes all keys in a Kubernetes secret for easy viewing
- `k8s_pod_restart_detector.sh`: Identifies pods in a Kubernetes namespace that have been restarting frequently
- `k8s_node_resource_usage.sh`: Summarizes CPU and Memory usage across all nodes in a cluster
- `k8s_pod_logs_by_label.sh`: Fetches logs from all pods matching a specific label
- `k8s_check_resource_limits.sh`: Verifies that all pods in a namespace have CPU and Memory limits defined
- `k8s_unused_secrets_finder.sh`: Identifies Kubernetes secrets in a namespace that are not currently used by any Pod or ServiceAccount

### Terraform Scripts

- `envsetup.sh`: Scripts for installing all needed dependencies for Terraform
- `tr_init.sh`: Scripts for checking if all needed dependencies for Terraform are installed
- `tf_check_fmt.sh`: Checks if Terraform code is properly formatted
- `tf_validate_all.sh`: Finds all directories containing Terraform files and runs 'terraform validate' in each
- `/up_py`:
  - `up.py`: Creating a Resource Group and other resource using python to bring up a machine in Azure
  - `up2.py`: Creating vm using python utilizing an already created Resource Group in Azure
- `/down_py`:
  - `down.py`: Deleting a vm on Azure by doing the opposite of creating (Destroying the VM first and etc)
  - `down2.py`: Deleting a vm on Azure only by the Resource Group (Destroying The Resource Group destroys all the resources inside it)

### JFrog Scripts

- `jfrog_config.sh`: Configures the JFrog CLI with server details
- `jfrog_upload.sh`: Uploads files or directories to Artifactory using JFrog CLI
- `jfrog_download.sh`: Downloads files or directories from Artifactory using JFrog CLI
- `jfrog_search.sh`: Searches for artifacts in Artifactory using JFrog CLI
- `jfrog_delete.sh`: Deletes artifacts from Artifactory with dry-run support
- `upload_generic.sh`: Uploads a file to Artifactory using curl and API key
- `pull_generic.sh`: Downloads a file from Artifactory using curl and API key

### Docker Scirpts

- `check_docker.sh`: Checks if docker and compose exists whitin you sys
- `docker_login.sh`: Check if you are logged into your DockerHub acc
- `docker_push_to_repo.sh`: Build & Push an existing image to Docker Hub
- `test_bash.sh`: Testing bash commands
- `clean_docker_ps.sh`: Clean the Docker from containers
- `clean_docker_images.sh`: Clean all the Docker images
- `install_docker.sh`: Removes previous version of docker and install the newst one
- `docker-vol-prune.sh`: Prune all unused Docker Volumes
- `docker-net-prune.sh`: Prune all unused Docker Networks
- `docker_tag_exists.sh`: Checks if a Docker tag exists in a remote registry without pulling the image
- `docker_image_size.sh`: Checks if a local Docker image exceeds a specified size limit
- `docker_clean_unused.sh`: Safely removes unused Docker images, containers, and volumes with dry-run support
- `docker_build_push.sh`: Builds and pushes a Docker image with support for multiple tags
- `docker_list_latest_images.sh`: Lists local Docker images using the 'latest' tag

### Azure Scripts

- `/python`:
  - `az_script_advance.py`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it
  - `az_script_using_sdk.py`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Uses Azure Python SDK)
- `az_script_advance.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it
- `az_script.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Hard Coded)
- `az_script_with_user.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Lets user chose everything)
- `az_devops_config.sh`: Configures Azure DevOps CLI with Organization URL and PAT
- `az_devops_list_pipelines.sh`: Lists Azure DevOps pipelines for a given project
- `az_devops_run_pipeline.sh`: Triggers an Azure DevOps pipeline run
- `az_devops_wait_pipeline.sh`: Waits for an Azure DevOps pipeline run to complete
- `az_devops_vars_util.sh`: Manages Azure DevOps variable groups via CLI.

### Azure DevOps Templates

Located in `az_devops_templates/`, these are reusable YAML templates for pipelines.

- `common/security_scans.yml`: Steps for Secret Scanning and SAST/SCA.
- `common/docker_build_push.yml`: Steps for Docker build, Trivy scan, and push.
- `jobs/build_test_job.yml`: Multi-language build/test job (.NET, C++, Node, etc).
- `jobs/deploy_k8s_job.yml`: Helm-based deployment job.
- `pipelines/nodejs_pipeline.yml`: Example Node.js CI/CD.
- `pipelines/python_pipeline.yml`: Example Python CI/CD.
- `pipelines/dotnet_pipeline.yml`: Example .NET CI/CD.
- `pipelines/cpp_pipeline.yml`: Example C++ CI.

### General Scripts

- `kill_proc.sh`: Kill the process by user choice
- `proc_exist_script.sh`: Check if the process exited and if hes running or not (also capbale of running the process and stopping it)
- `check_sys_info.sh`: Gives various Linux System information: Disk Usage, Sys Info, etc...
- `auto_completion.sh`: Allows you to insert cli linux apps to auto completion (if they exist on you machine) in .bashrc
- `bump_version.sh`: Allows you to bump versions for diffrent types of file, also creates a .bak file to backup (Work in Progress)
- `bump_version_nb.sh`: Allows you to bump versions for diffrent types of file without backup (Work in Progress)
- `validate_env_vars.sh`: Validates that required environment variables are set and not empty
- `wait_for_url.sh`: Waits for a URL to return a 200 OK status code
- `check_ssl_expiry.sh`: Checks the expiration date of an SSL certificate for a given domain
- `find_large_files.sh`: Finds files larger than a specified size in a directory
- `check_disk_space.sh`: Checks disk space and warns if usage exceeds a threshold
- `send_slack_notification.sh`: Sends a message to a Slack channel using a Webhook URL
- `hadolint_scan.sh`: Scans a Dockerfile using Hadolint (via Docker) to ensure best practices
- `check_url_content.sh`: Waits for a URL to return 200 OK and verifies that the body contains a specific string

### AWS Scripts

- `aws_s3_sync.sh`: Syncs a local directory with an S3 bucket
- `aws_list_old_ebs_snapshots.sh`: Lists AWS EBS snapshots older than a specified number of days

### Github Scripts

- `commit_script.sh`: Commiting the changes you created by branch and message with the files you added
- `commit_script_no_push.sh`: Commiting the changes you created by branch and message with the files you added without pushing the changes
- `check_alias.sh`: Checking which alias is used in your git
- `init_repo.sh`: Init a new repository with main branch (Work in progress)
- `gh_get_latest_release.sh`: Fetches the latest release tag from a GitHub repository using the GitHub API
- `gh_download_release_asset.sh`: Downloads a specific asset from the latest GitHub release of a repository
- `gh_create_release.sh`: Creates a GitHub release via the API
- `gh_list_pull_requests.sh`: Lists open pull requests for a repository using the GitHub API
- `git_cleanup_merged_branches.sh`: Deletes local branches that have been merged into the default branch

## Usage

Each script directory contains specific instructions for running the scripts. Most scripts can be executed directly after making them executable:

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

## General Recent Updates

- Added Terraform scripts for installing dependencies
- Fixed issues with Kubernetes initialization script
- Added ArgoCD installation script
- Added Github scripts for repositories
- Added general usage scripts
- Added 2 new scripts for github folder
- Added new script for installtion of docker

  #### Updates By Week - [ 18.04.25 -> 24.04.25 ]

  - Added 2 new docker scripts
    - docker-vol-prune.sh
    - docker-net-prune.sh

## Contributing

Feel free to submit pull requests with additional scripts or improvements to existing ones.

## License

MIT

## Contributors

All rights reserved,
Made by Kobi Kuzi.
