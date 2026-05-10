# Azure DevOps Pipeline Templates

This directory contains robust and reusable Azure DevOps YAML templates following the "Left Shift" security approach and DRY (Don't Repeat Yourself) principles.

## 📂 Structure

- **common/**: Reusable step-level templates.
  - `security_scans.yml`: Integrated security checks (Gitleaks, SonarCloud placeholder).
  - `docker_build_push.yml`: Standardized Docker build, scan (Trivy), and push process.
  - `notifications.yml`: Email notification step.
  - `gitflow_triggers.yml`: Reference for GitFlow-based branch triggers.
  - `jfrog_operations.yml`: Artifactory upload/download and Xray scanning.
  - `run_script_util.yml`: Generic wrapper to run repository scripts.
  - `gitflow_logic.yml`: Reusable logic to determine environment from branch name.
- **jobs/**: Reusable job-level templates.
  - `build_test_job.yml`: A multi-language build and test job (Node.js, Python, Java, .NET, C++). Now supports optional Xray scans.
  - `deploy_k8s_job.yml`: Standardized deployment job using Helm.
  - `deploy_webapp_job.yml`: Deployment to Azure App Service.
  - `deploy_vm_job.yml`: Deployment/execution on Azure VMs.
- **pipelines/**: Example full CI/CD pipelines.
  - `nodejs_pipeline.yml`: Full pipeline for Node.js applications.
  - `python_pipeline.yml`: Full pipeline for Python applications.
  - `dotnet_pipeline.yml`: CI/CD for .NET applications with notifications.
  - `cpp_pipeline.yml`: CI for C++ applications with failure alerts.
- **pipelines/utils/**: Specialized utility pipelines.
  - `agent_maintenance.yml`: Daily cleanup for self-hosted agents.
  - `compliance_scan.yml`: On-demand security audit pipeline.

## 🚀 How to use

To use these templates in your own Azure DevOps project:

1. Reference the repository containing these templates in your `azure-pipelines.yml`.
2. Use the `template` keyword to include the desired job or step.

### Example: Running a repository script

```yaml
steps:
  - template: common/run_script_util.yml
    parameters:
      scriptPath: 'general_scripts/check_disk_space.sh'
      scriptArguments: '--threshold 80'
```

## 🛡️ Left Shift Security

- **Secret Scanning**: Gitleaks is integrated into the build process.
- **SCA/SAST**: SonarCloud and JFrog Xray are supported.
- **Container Scanning**: Trivy is used to scan Docker images for vulnerabilities.
