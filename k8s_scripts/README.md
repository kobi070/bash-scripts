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

11. **k8s_resource_usage_percentage.sh**
    Calculates Pod resource usage (CPU/Memory) as a percentage of their defined limits.

12. **k8s_configmap_secret_sync_check.sh**
    Verifies that all ConfigMaps and Secrets referenced in Deployments and StatefulSets actually exist.

### Cleanup & Compliance
13. **k8s_find_unused_pvcs.sh**
    Identifies PersistentVolumeClaims (PVCs) that are not currently used by any Pods.

14. **k8s_orphaned_resources.sh**
    Heuristically identifies ConfigMaps and Secrets that are not referenced by any workloads.

15. **k8s_audit_pdb.sh**
    Identifies Deployments and StatefulSets missing PodDisruptionBudgets (PDB).

16. **k8s_unused_secrets_finder.sh**
    Identifies secrets not used by any Pod or ServiceAccount.

### Maintenance & Utilities
17. **k8s_secret_expiry_check.sh**
    Identifies TLS secrets in the cluster that are nearing expiration.

18. **k8s_copy_secret.sh**
    Copies a Kubernetes secret from one namespace to another.

19. **k8s_node_drain_helper.sh**
    Assess the impact of draining a node (PDBs, local storage, etc.).

20. **k8s_ingress_audit.sh**
    Summarizes Ingress resources, including their hosts, paths, and TLS status.

## 🚀 Usage examples

### Check Cluster Usage
```bash
./k8s_node_resource_usage.sh
```

### Assess Node Drain Impact
```bash
./k8s_node_drain_helper.sh <node_name>
```

### Check Pod Resource Usage Percentage
```bash
./k8s_resource_usage_percentage.sh [namespace]
```

### Decode Secrets
```bash
./k8s_decode_secret.sh <secret_name> [namespace] [--raw]
```

### Find Orphaned Resources
```bash
./k8s_orphaned_resources.sh [namespace]
```

### Audit Ingress Resources
```bash
./k8s_ingress_audit.sh [namespace]
```

### Copy Secret to another Namespace
```bash
./k8s_copy_secret.sh <secret_name> <source_namespace> <target_namespace>
```

## ✅ Prerequisites

- `kubectl` installed and configured.
- `minikube` installed (for minikube scripts).
- `jq` installed for JSON parsing.
- Ensure your `kubectl` context is correctly set before running these scripts.
