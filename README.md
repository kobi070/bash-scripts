# Bash Scripts

A collection of utility scripts for automating installations and configurations across different environments.

## Repository Structure

This repository contains scripts organized into the following categories:

- **argocd_scripts**: Scripts for installing and configuring ArgoCD on Kubernetes
- **docker_scripts**: Docker-related automation scripts
- **k8s_scripts**: Kubernetes installation and configuration utilities
- **terraform_scripts**: Scripts for automating Terraform installations and dependencies
- **az_scripts**: Scripts for automating Azure installations and etc
- **general_scripts**: Scripts for general use cases
- **github_scripts**: Scripts for general use cases in Github repositories

## Available Scripts

### ArgoCD Scripts

- `install-argocd.sh`: Installs ArgoCD on your own Kubernetes cluster

### Kubernetes Scripts

- `ini_k8s.sh`: Kubernetes initialization script (recently fixed)
- `minikube_status.sh`: Minikube status script
- `minikube_start.sh `: Starts minikube
- `minikube_stop.sh `: Stops minikube
- `minikube_install.sh `: Installs minikube if its not installed yet, you need to have docker installed for this to work

### Terraform Scripts

- `envsetup.sh`: Scripts for installing all needed dependencies for Terraform
- `tr_init.sh`: Scripts for checking if all needed dependencies for Terraform are installed
- `/up_py`:
  - `up.py`: Creating a Resource Group and other resource using python to bring up a machine in Azure
  - `up2.py`: Creating vm using python utilizing an already created Resource Group in Azure
- `/down_py`:
  - `down.py`: Deleting a vm on Azure by doing the opposite of creating (Destroying the VM first and etc)
  - `down2.py`: Deleting a vm on Azure only by the Resource Group (Destroying The Resource Group destroys all the resources inside it)

### Docker Scirpts

- `check_docker.sh`: Checks if docker and compose exists whitin you sys
- `docker_login.sh`: Check if you are logged into your DockerHub acc
- `docker_push_to_repo.sh`: Build & Push an existing image to Docker Hub
- `test_bash.sh`: Testing bash commands
- `clean_docker_ps.sh`: Clean the Docker from containers
- `clean_docker_images.sh`: Clean all the Docker images
- `install_docker.sh`: Removes previous version of docker and install the newst one

### Azure Scripts

- `/python`:
  - `az_script_advance.py`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it
  - `az_script_using_sdk.py`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Uses Azure Python SDK)
- `az_script_advance.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it
- `az_script.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Hard Coded)
- `az_script_with_user.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Lets user chose everything)

### General Scripts

- `kill_proc.sh`: Kill the process by user choice
- `proc_exist_script.sh`: Check if the process exited and if hes running or not (also capbale of running the process and stopping it)
- `check_sys_info.sh`: Gives various Linux System information: Disk Usage, Sys Info, etc...
- `auto_completion.sh`: Allows you to insert cli linux apps to auto completion (if they exist on you machine) in .bashrc
- `bump_version.sh`: Allows you to bump versions for diffrent types of file, also creates a .bak file to backup (Work in Progress)
- `bump_version_nb.sh`: Allows you to bump versions for diffrent types of file without backup (Work in Progress)

### Github Scripts

- `commit_script.sh`: Commiting the changes you created by branch and message with the files you added
- `commit_script_no_push.sh`: Commiting the changes you created by branch and message with the files you added without pushing the changes
- `check_alias.sh`: Checking which alias is used in your git
- `init_repo.sh`: Init a new repository with main branch (Work in progress)

## Usage

Each script directory contains specific instructions for running the scripts. Most scripts can be executed directly after making them executable:

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

## Recent Updates

- Added Terraform scripts for installing dependencies
- Fixed issues with Kubernetes initialization script
- Added ArgoCD installation script
- Added Github scripts for repositories
- Added general usage scripts
- Added 2 new scripts for github folder
- Added new script for installtion of docker

## Contributing

Feel free to submit pull requests with additional scripts or improvements to existing ones.

## License

MIT

## Contributors

All rights reserved,
Made by Kobi Kuzi.
