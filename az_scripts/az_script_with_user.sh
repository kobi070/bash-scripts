#!/bin/bash

# Exit on error
set -e

# Configuration
AZURE_SUBSCRIPTION="3f79a68d-cf0d-4291-a31f-185897f7fda1"
AZURE_DEVOPS_ORG="markveltzer"
AZURE_DEVOPS_PROJECT="training"
RESOURCE_GROUP="KobiResourceGroup"
LOCATION="eastus"
ACR_NAME="kobi070"
REPO_NAME="kobi_script_rep2"
PIPELINE_NAME="kobi_pipeline2"
SERVICE_CONNECTION_NAME="kobiconnect"
SP_APP_ID="8ecdf10e-c3e0-4349-b9f2-ef531b1222a5"
SP_TENANT_ID="d12c5e26-8134-4d75-adb9-89c53343dc6b"
SUBSCRIPTION_NAME="Basic"
PAT="EXysGY6nOWBETGkJNovT9vkeSAxLdoDp1uPYrCRgB2uospP7IVY7JQQJ99BCACAAAAAAAAAAAAASAZDO0Tu4"  # Your PAT

# Function to run commands with debug output
run_command() {
    echo "Executing: $*"
    output=$("$@" 2>&1)
    result=$?
    echo "Output: $output"
    
    if [ $result -ne 0 ]; then
        echo "Command failed: $*"
        echo "Exit code: $result"
        exit 1
    fi
}

# Set Azure subscription
echo "Setting Azure subscription..."
run_command az account set --subscription "$AZURE_SUBSCRIPTION"

echo "Verifying active subscription..."
run_command az account show --output table

# Create resource group
echo "Creating resource group $RESOURCE_GROUP..."
run_command az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# Create Azure Container Registry
echo "Creating Azure Container Registry $ACR_NAME..."
run_command az acr create --resource-group "$RESOURCE_GROUP" --name "$ACR_NAME" --sku Basic

# Configure Azure DevOps CLI
echo "Configuring Azure DevOps CLI..."
run_command az devops configure --defaults "organization=https://dev.azure.com/$AZURE_DEVOPS_ORG" "project=$AZURE_DEVOPS_PROJECT"

# Create a new repository in Azure Repos
echo "Creating repository $REPO_NAME..."
run_command az repos create --name "$REPO_NAME"

# Clone the repository locally and upload sample code
echo "Cloning repository and uploading sample code..."
repo_url="https://$PAT@dev.azure.com/$AZURE_DEVOPS_ORG/$AZURE_DEVOPS_PROJECT/_git/$REPO_NAME"
run_command git clone "$repo_url"
cd "$REPO_NAME" || exit 1

# Create a sample Dockerfile
echo "FROM alpine" > Dockerfile
echo 'CMD ["echo", "Hello from my container!"]' >> Dockerfile

# Git commands to commit and push
run_command git add .
run_command git commit -m "Initial commit with sample Dockerfile"
run_command git push "https://$PAT@dev.azure.com/$AZURE_DEVOPS_ORG/$AZURE_DEVOPS_PROJECT/_git/$REPO_NAME" master

# Create the pipeline YAML file
cat > azure-pipelines.yml << EOF
trigger:
- master
pool:
  vmImage: 'ubuntu-latest'
variables:
  dockerRegistryServiceConnection: '$SERVICE_CONNECTION_NAME'
  imageRepository: 'myimage'
  tag: '\$(Build.BuildId)'
steps:
- task: Docker@2
  displayName: 'Build and push Docker image'
  inputs:
    command: 'buildAndPush'
    repository: '\$(imageRepository)'
    dockerfile: '\$(Build.SourcesDirectory)/Dockerfile'
    containerRegistry: '\$(dockerRegistryServiceConnection)'
    tags: '\$(tag)'
EOF

# Commit and push the pipeline file
run_command git add azure-pipelines.yml
run_command git commit -m "Add pipeline configuration"
run_command git push "https://$PAT@dev.azure.com/$AZURE_DEVOPS_ORG/$AZURE_DEVOPS_PROJECT/_git/$REPO_NAME" master

# Create and run the pipeline
echo "Creating pipeline $PIPELINE_NAME..."
run_command az pipelines create \
    --name "$PIPELINE_NAME" \
    --repository "$REPO_NAME" \
    --branch "master" \
    --yaml-path "azure-pipelines.yml" \
    --repository-type "tfsgit"

echo "Triggering pipeline $PIPELINE_NAME run..."
run_command az pipelines run --name "$PIPELINE_NAME"

echo "Script completed successfully!"