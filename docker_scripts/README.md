# docker_scripts

This directory contains scripts for managing **Docker** environments, image workflows, and container security.

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

### Cleanup & Maintenance
7. **docker_clean_unused.sh**
   Prunes unused containers, images, and networks with dry-run support.

8. **docker-vol-prune.sh / docker-net-prune.sh**
   Specific scripts for pruning volumes and networks.

9. **clean_docker_images.sh / clean_docker_ps.sh**
   Quick cleanup scripts for images and containers.

### Security
10. **trivyScans.sh**
    Uses Trivy to scan images for vulnerabilities and generates reports.

11. **docker_get_container_ip.sh**
    Retrieves the IP address of a running Docker container.

## 🚀 Usage

```bash
chmod +x <script_name>.sh
./<script_name>.sh
```

✅ Prerequisites

- Docker Engine installed and running.
- `trivy` installed (for `trivyScans.sh`).

📘 Notes
- Always use the `--dry-run` flag where available before performing cleanup operations.
