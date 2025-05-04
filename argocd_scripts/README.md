# argocd_scripts

This repository contains shell scripts for setting up and managing **Argo CD**, a declarative, GitOps continuous delivery tool for Kubernetes.

## 📜 Scripts Overview

1. **install-argocd.sh**  
   Installs Argo CD on a Kubernetes cluster. This script typically applies the official Argo CD manifests and may include additional setup steps such as namespace creation and port forwarding.

## 🚀 Usage

To install Argo CD, run the following command in your terminal:

```bash
./install-argocd.sh
```

Ensure you have the necessary permissions and that your Kubernetes context is correctly configured.

✅ Prerequisites

- A running Kubernetes cluster (e.g., Minikube, kind, or a cloud provider).
- kubectl installed and configured.
- Internet access to fetch Argo CD manifests from the official repository.
📘 Notes
- After installation, you can access the Argo CD UI by port-forwarding the Argo CD server service.
- Default credentials and further configuration steps can be found in the official Argo CD documentation.
