# docker_scripts

## 📖 Overview
This directory contains scripts for managing **Docker** environments, image workflows, and container security. It includes tools for installation, image optimization, and vulnerability scanning.

## 📜 Scripts Overview

### Installation & Setup
1. **install_docker.sh**
   Automates the installation of the latest Docker version on Linux.

2. **check_docker.sh**
   Verifies if Docker and Docker Compose are installed and functional.

3. **docker_login.sh**
   Handles authentication to Docker Hub or private registries.

### Image Management
4. **docker_build_push.sh**
   Builds and pushes images with support for multiple tags and build-args.

5. **docker_tag_exists.sh**
   Checks if a specific tag exists in a remote registry without pulling the image.

6. **docker_image_size.sh**
   Validates that a local image does not exceed a specified size limit.

7. **docker_push_to_repo.sh**
   Standardized script for pushing images to a target repository.

8. **docker-tag-push.sh / docker-tag-push-from-file.sh**
   Utilities for tagging and pushing images individually or from a list.

### Cleanup & Maintenance
9. **docker_clean_unused.sh**
   Prunes unused containers, images, and networks with dry-run support.

10. **docker-vol-prune.sh / docker-net-prune.sh**
    Specific scripts for pruning volumes and networks.

11. **clean_docker_images.sh / clean_docker_ps.sh**
    Quick cleanup scripts for images and containers.

### Security
12. **trivyScans.sh**
    Uses Trivy to scan images for vulnerabilities and generates reports.

11. **docker_get_container_ip.sh**
    Retrieves the IP address of a running Docker container.

## 🚀 Usage

### Build and Push Image
```bash
./docker_build_push.sh --image "my-app" --tag "v1.0.0" --push
```

### Scan Image for Vulnerabilities
```bash
./trivyScans.sh my-app:v1.0.0
```

## ✅ Prerequisites

- Docker Engine installed and running.
- `trivy` installed (for `trivyScans.sh`).

## 📘 Notes
- Always use the `--dry-run` flag where available before performing cleanup operations.
