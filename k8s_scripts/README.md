# k8s_scripts

## 📖 Overview
This directory contains scripts for managing **Kubernetes** resources and **Minikube** environments. It covers cluster initialization, resource monitoring, and debugging utilities.

## 📜 Scripts Overview

### Minikube Lifecycle
1. **minikube_install.sh**
   Installs Minikube on the local system.

2. **minikube_start.sh / minikube_stop.sh / minikube_status.sh**
   Commands for managing the Minikube cluster lifecycle.

### Cluster Management
3. **init_k8s.sh**
   Initializes the Kubernetes environment and checks core components.

4. **k8s_create_ns.sh / k8s_del_ns.sh**
   Quickly create or delete Kubernetes namespaces.

5. **k8s_wait_ready.sh**
   Waits for deployments, statefulsets, or daemonsets to become ready.

6. **k8s_node_resource_usage.sh**
   Summarizes CPU and Memory usage across all nodes.

### Monitoring & Debugging
7. **k8s_pod_restart_detector.sh**
   Identifies pods that are restarting frequently.

8. **k8s_pod_logs_by_label.sh**
   Aggregates logs from all pods matching a specific label.

9. **k8s_decode_secret.sh**
   Decodes all Base64 values in a Kubernetes secret for easy inspection.

10. **k8s_check_resource_limits.sh**
    Verifies that all pods in a namespace have resource limits defined.

11. **k8s_find_unused_pvcs.sh**
    Identifies PersistentVolumeClaims (PVCs) that are not currently used by any Pods.

## 🚀 Usage

### Check Cluster Usage
```bash
./k8s_node_resource_usage.sh
```

### Decode Secrets
```bash
./k8s_decode_secret.sh <secret_name> [namespace] [--raw]
```

## ✅ Prerequisites

- `kubectl` installed and configured.
- `minikube` installed (for minikube scripts).
- `jq` installed for JSON parsing.
