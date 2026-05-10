# Azure DevOps Pipeline Templates

This directory contains robust and reusable Azure DevOps YAML templates following the "Left Shift" security approach and DRY (Don't Repeat Yourself) principles.

## 📂 Structure

- **common/**: Reusable step-level templates.
  - `security_scans.yml`: Integrated security checks (Gitleaks, SonarCloud placeholder).
  - `docker_build_push.yml`: Standardized Docker build, scan (Trivy), and push process.
  - `notifications.yml`: Email notification step.
  - `gitflow_triggers.yml`: Reference for GitFlow-based branch triggers.
- **jobs/**: Reusable job-level templates.
  - `build_test_job.yml`: A multi-language build and test job (Node.js, Python, Java, .NET, C++).
  - `deploy_k8s_job.yml`: A standardized deployment job using Helm.
- **pipelines/**: Example full CI/CD pipelines.
  - `nodejs_pipeline.yml`: Full pipeline for Node.js applications.
  - `python_pipeline.yml`: Full pipeline for Python applications.
  - `dotnet_pipeline.yml`: CI/CD for .NET applications with notifications.
  - `cpp_pipeline.yml`: CI for C++ applications with failure alerts.

## 🚀 How to use

To use these templates in your own Azure DevOps project:

1. Reference the repository containing these templates in your `azure-pipelines.yml`.
2. Use the `template` keyword to include the desired job or step.

### Example

```yaml
jobs:
  - template: jobs/build_test_job.yml
    parameters:
      language: 'nodejs'
```

## 🛡️ Left Shift Security

- **Secret Scanning**: Gitleaks is integrated into the build process.
- **SCA/SAST**: Placeholders and integration points for SonarCloud and other tools.
- **Container Scanning**: Trivy is used to scan Docker images for vulnerabilities before pushing them to the registry.
