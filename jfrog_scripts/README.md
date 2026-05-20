# jfrog_scripts

This directory contains scripts for managing **JFrog Artifactory** and **Xray** using the JFrog CLI and APIs.

## 📖 Overview
These scripts handle server configuration, artifact management, and security scanning.

## 📜 Scripts Overview

1. **jfrog_config.sh**: Server configuration for JFrog CLI.
2. **jf_xray_scan.sh**: Security scans for artifacts and builds using Xray.
3. **jf_node_config.sh / jf_python_config.sh**: Package manager configuration for Artifactory.
4. **jfrog_upload.sh / jfrog_download.sh**: High-level artifact upload and download.
5. **jfrog_search.sh / jfrog_delete.sh**: Artifact discovery and safe removal.
6. **jf_docker_push.sh**: Pushes Docker images to Artifactory repositories.
7. **jf_release_bundle.sh**: Management of JFrog Release Bundles.
8. **upload_generic.sh / pull_generic.sh**: API-based management using `curl`.
9. **jf_cleanup_old_artifacts.sh**: Automated cleanup of artifacts older than N days.

## 🚀 Usage

### Configure CLI
```bash
./jfrog_config.sh --url "https://artifactory.example.com" --token "$JF_AUTH_TOKEN"
```

### Upload Artifact
```bash
./jfrog_upload.sh --repo "generic-local" --source "./build/app.zip"
```

### Cleanup Old Artifacts
```bash
./jf_cleanup_old_artifacts.sh generic-local 30 --delete
```

## ✅ Prerequisites

- JFrog CLI (`jf` or `jfrog`) installed.
- Valid Artifactory credentials or Access Token.
- `curl` and `jq` installed.

## 📘 Notes
- It is recommended to set `JF_AUTH_TOKEN` or `JFROG_API_KEY` as environment variables instead of passing them as arguments.
