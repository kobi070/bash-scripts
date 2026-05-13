# jfrog_scripts

## 📖 Overview
This directory contains scripts for automating interactions with **JFrog Artifactory** and managing the **JFrog CLI**. It covers artifact management, security scanning, and package manager configuration.

## 📜 Scripts Overview

1. **jfrog_config.sh**
   Configures the JFrog CLI with server details, including URL and authentication (Access Token/API Key).

2. **jfrog_upload.sh**
   Uploads files or directories to a specified Artifactory repository using the JFrog CLI.

3. **jfrog_download.sh**
   Downloads artifacts from Artifactory using the JFrog CLI.

4. **jfrog_search.sh**
   Searches for artifacts in Artifactory repositories.

5. **jfrog_delete.sh**
   Safely deletes artifacts from Artifactory, supporting dry-run mode.

6. **jf_xray_scan.sh**
   Triggers an Xray scan for a specific artifact or build to identify security vulnerabilities.

7. **jf_docker_push.sh**
   Pushes Docker images to Artifactory using the JFrog CLI.

8. **jf_node_config.sh / jf_python_config.sh**
   Configures package managers (npm/pip) to use Artifactory as a registry.

9. **jf_release_bundle.sh**
   Manages the creation and distribution of JFrog Release Bundles.

10. **upload_generic.sh / pull_generic.sh**
    Generic scripts to upload/download files using `curl` and Artifactory APIs directly.

## 🚀 Usage

### Configure CLI
```bash
./jfrog_config.sh --url "https://artifactory.example.com" --token "$JF_AUTH_TOKEN"
```

### Upload Artifact
```bash
./jfrog_upload.sh --repo "generic-local" --source "./build/app.zip"
```

## ✅ Prerequisites

- JFrog CLI (`jf` or `jfrog`) installed.
- Valid Artifactory credentials or Access Token.
- `curl` installed for generic scripts.

## 📘 Notes
- It is recommended to set `JF_AUTH_TOKEN` or `JFROG_API_KEY` as environment variables instead of passing them as arguments.
