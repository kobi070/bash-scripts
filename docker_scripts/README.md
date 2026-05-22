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

7. **docker_layer_analysis.sh**
   Analyzes local Docker image layers and identifies the largest contributors.

8. **docker_push_to_repo.sh**
   Standardized script for pushing images to a target repository.

9. **docker-tag-push.sh / docker-tag-push-from-file.sh**
   Utilities for tagging and pushing images individually or from a list.

10. **docker_list_latest_images.sh**
    Lists all local images that are using the 'latest' tag.

### Cleanup & Maintenance
11. **docker_clean_unused.sh**
    Prunes unused containers, images, and networks with dry-run support.

12. **docker-vol-prune.sh / docker-net-prune.sh**
    Specific scripts for pruning volumes and networks.

13. **clean_docker_images.sh / clean_docker_ps.sh**
    Quick cleanup scripts for images and containers.

### Security & Auditing
14. **trivyScans.sh**
    Uses Trivy to scan images for vulnerabilities and generates reports.

15. **docker_inspect_security.sh**
    Inspects a running container for security misconfigurations.

16. **docker_audit_security.sh**
    Performs a security audit on running containers to identify root users, privileged mode, etc.

17. **docker_root_check.sh**
    Scans running containers to identify any running as the root user.

18. **docker_get_container_ip.sh**
    Retrieves the IP address of a running Docker container.

19. **docker_layer_size_analyzer.sh**
    Detailed analysis of Docker image layers to identify size contributors.

20. **docker_image_vulnerability_summary.sh**
    Summarizes vulnerability counts by severity from a Trivy JSON report.

21. **docker_image_history_audit.sh**
    Audits Docker image history for sensitive commands and oversized layers.

22. **docker_image_promoter.sh**
    Streamlines the process of pulling, re-tagging, and pushing a Docker image between registries.

## 🚀 Usage

### Build and Push Image
```bash
./docker_build_push.sh --image "my-app" --tag "v1.0.0" --push
```

### Scan Image for Vulnerabilities
```bash
./trivyScans.sh my-app:v1.0.0
```

### Analyze Image Layers
```bash
./docker_layer_analysis.sh my-app:v1.0.0
```

### Inspect Container Security
```bash
./docker_inspect_security.sh <container_name_or_id>
```

### Security Audit
```bash
./docker_audit_security.sh [container_name]
```

### Promote Image
```bash
./docker_image_promoter.sh my-registry.com/app:1.0 prod-registry.com/app:1.0
```

## ✅ Prerequisites

- Docker Engine installed and running.
- `trivy` installed (for `trivyScans.sh`).

## 📘 Notes
- Always use the `--dry-run` flag where available before performing cleanup operations.
