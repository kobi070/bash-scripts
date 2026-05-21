# argocd_scripts

## 📖 Overview
This directory contains shell scripts for setting up and managing **Argo CD**, a declarative, GitOps continuous delivery tool for Kubernetes.

## 📜 Scripts Overview

1. **install-argocd.sh**  
   Installs Argo CD on a Kubernetes cluster by applying the official manifests and setting up the necessary namespace.

2. **argocd_app_sync.sh**
   Syncs an Argo CD application and waits for it to reach a `Healthy` and `Synced` status. Includes timeout handling.

3. **argocd_list_apps.sh**
   Lists all applications managed by Argo CD along with their health and synchronization status.

4. **argocd_app_diff.sh**
   Displays the diff between Git and Cluster state for a specified ArgoCD application.

## 🚀 Usage

### Install Argo CD
```bash
./install-argocd.sh
```

### Sync an Application
```bash
./argocd_app_sync.sh <app_name>
```

### List Applications
```bash
./argocd_list_apps.sh
```

### App Diff
```bash
./argocd_app_diff.sh <app_name>
```

## ✅ Prerequisites

- A running Kubernetes cluster.
- `kubectl` installed and configured.
- `argocd` CLI installed for app management scripts.

## 📘 Notes
- After installation, use `kubectl port-forward` to access the Argo CD UI.
