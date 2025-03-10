#!/bin/bash
set -e

# Ask the user for input values
read -p "Enter the name for the repository: " repo_name
read -p "Enter the name for the pipeline: " pipeline_name
read -p "Enter the name for the container registry: " acr_name
read -p "Enter the name of the resource group: " resource_group
read -p "Enter the Azure DevOps organization URL (e.g., https://dev.azure.com/markveltzer): " org_url
read -p "Enter the Azure DevOps project name (e.g., training): " project_name

# Create a new source code repository
az repos create --name "$repo_name" --project "$project_name" --organization "$org_url"

# Upload some code to the repository
cd /tmp
mkdir "$repo_name"
cd "$repo_name"
git init
echo "print('hello world')" > hello.py
git add hello.py
git commit -m "Init commit"

# Set the remote origin for the Azure DevOps repository
git remote add origin "$org_url/$project_name/_git/$repo_name"

# Push the code to Azure DevOps
git push -u origin master

# Creates a new container registry
az acr create --name "$acr_name" --resource-group "$resource_group" --sku "Basic" --location "eastus"

# Create a connection to the newly created container registry
az acr login --name "$acr_name"

# Create a new pipeline with the repository and the container registry
az pipelines create --name "$pipeline_name" --repository "$repo_name" --organization "$org_url" --project "$project_name" --repository-type "tfsgit" --branch "master" --yaml-path "azure-pipelines.yml" --service-connection "$acr_name"

# Run the pipeline once
az pipelines run --name "$pipeline_name" --organization "$org_url" --project "$project_name"
