#!/bin/bash
set -e

# Create a new source code repository
az repos create --name "KobiRepo" --project "training" --organization "https://dev.azure.com/markveltzer"

# Upload some code to the repository
cd /tmp
mkdir myfirstrepo
cd myfirstrepo
git init
echo "print('hello world')" > hello.py
git add hello.py
git commit -m "Init commit"

# Set the remote origin for the Azure DevOps repository
git remote add origin https://dev.azure.com/markveltzer/training/_git/KobiRepo

# Push the code to Azure DevOps
git push -u origin master

# Creates a new container registry
az acr create --name "kobifirstacr" --resource-group "kobifirstresourcegroup" --sku "Basic" --location "eastus"

# Create a connection to the newly created container registry
az acr login --name "kobifirstacr"

# Create a new pipeline with the repository and the container registry
az pipelines create --name "KobiPipeline" --repository "KobiRepo" --organization "https://dev.azure.com/markveltzer" --project "training" --repository-type "tfsgit" --branch "master" --yaml-path "azure-pipelines.yml" --service-connection "kobifirstacr"

# Run the pipeline once
az pipelines run --name "KobiPipeline" --organization "https://dev.azure.com/markveltzer" --project "training"
