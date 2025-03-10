# Bash Scripts

A collection of utility scripts for automating installations and configurations across different environments.

## Repository Structure

This repository contains scripts organized into the following categories:

- **argocd_scripts**: Scripts for installing and configuring ArgoCD on Kubernetes
- **docker_scripts**: Docker-related automation scripts
- **k8s_scripts**: Kubernetes installation and configuration utilities
- **terraform_scripts**: Scripts for automating Terraform installations and dependencies

## Available Scripts

### ArgoCD Scripts
- `install-argocd.sh`: Installs ArgoCD on your own Kubernetes cluster

### Kubernetes Scripts
- `ini_k8s.sh`: Kubernetes initialization script (recently fixed)

### Terraform Scripts
- `envsetup.sh`: Scripts for installing all needed dependencies for Terraform
- `tr_init.sh`: Scripts for checking if all needed dependencies for Terraform are installed

### Docker Scirpts
- `check_docker.sh`: Checks if docker and compose exists whitin you sys
- `docker_login.sh`: Check if you are logged into your DockerHub acc
- `docker_push_to_repo.sh`: Build & Push an existing image to Docker Hub
- `test_bash.sh`: Testing bash commands

### Azure Scripts
- `az_script_advance.py`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it 
- `az_script_advance.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it
- `az_script.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Hard Coded)
- `az_script_with_user.sh`: Creates a Repo inside Azure DevOps, Pushing files and Creating a Pipeline and running it (Lets user chose everything)

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

## Contributing

Feel free to submit pull requests with additional scripts or improvements to existing ones.

## License

[Add your license information here]
