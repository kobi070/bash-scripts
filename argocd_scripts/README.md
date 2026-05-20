# argocd_scripts

This directory contains scripts for managing **ArgoCD** installations and GitOps application management on Kubernetes.

## 📖 Overview
These scripts handle ArgoCD installation, application synchronization, and health monitoring.

## 📜 Scripts Overview

1. **install-argocd.sh**: Automated ArgoCD installation on a Kubernetes cluster.
2. **argocd_app_sync.sh**: Syncs applications and waits for health/sync status.
3. **argocd_list_apps.sh**: Lists all applications and their health status.
4. **argocd_app_diff.sh**: Shows the diff between Git and the Cluster for an application.

## 🚀 Usage

### Install ArgoCD
```bash
./install-argocd.sh
```

### Sync Application
```bash
./argocd_app_sync.sh my-app
```

### List Applications
```bash
./argocd_list_apps.sh
```

## ✅ Prerequisites

- `kubectl` installed and configured.
- `argocd` CLI installed.
- Access to a Kubernetes cluster.

## 📘 Notes
- Ensure you are logged into the ArgoCD server before running synchronization scripts.
