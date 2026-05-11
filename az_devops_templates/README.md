# Azure DevOps YAML Templates

A collection of modular and reusable **Azure DevOps** templates designed to implement standardized CI/CD pipelines with a focus on security and efficiency.

## 📂 Structure

The templates are organized into three main categories:

### 1. Common Steps (`common/`)
- `security_scans.yml`: Integrated Gitleaks (secrets), SonarCloud (SAST), Trivy (containers), and JFrog Xray.
- `docker_build_push.yml`: Standardized workflow for building, scanning, and pushing Docker images.
- `gitflow_logic.yml`: Shared logic for branch-based environment detection.
- `jfrog_operations.yml`: Common tasks for interacting with JFrog Artifactory.

### 2. Standardized Jobs (`jobs/`)
- `build_test_job.yml`: A multi-language job template supporting .NET, C++, Node.js, and Python.
- `deploy_k8s_job.yml`: Helm-based deployment job for Kubernetes.
- `deploy_webapp_job.yml`: Job for deploying to Azure App Services.
- `deploy_vm_job.yml`: Script-based deployment for Virtual Machines.

### 3. Pipeline Examples (`pipelines/`)
Ready-to-use pipeline examples for different stacks:
- `nodejs_pipeline.yml`, `python_pipeline.yml`, `dotnet_pipeline.yml`, `cpp_pipeline.yml`.

## 🚀 Usage

Reference these templates in your `azure-pipelines.yml` file:

```yaml
jobs:
- template: jobs/build_test_job.yml@templates
  parameters:
    language: 'nodejs'
    buildSteps:
      - script: npm install && npm run build
```

## 🛡️ Security Features

These templates implement a **Left-Shift** security approach:
- **Secret Scanning**: Gitleaks runs on every PR.
- **Container Scanning**: Trivy scans images before they are pushed to registries.
- **Artifact Scanning**: JFrog Xray ensures artifacts are free from vulnerabilities.

## ✅ Verification

To validate changes to these templates:
```bash
python3 -c "import yaml; yaml.safe_load(open('your_template.yml'))"
```
