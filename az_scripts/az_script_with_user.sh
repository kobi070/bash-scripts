#!/bin/bash
set -e

# Ask the user for input values
read -p "Enter the name for the repository: " repo_name
read -p "Enter the name for the pipeline: " pipeline_name
read -p "Enter the name of the resource group: " resource_group

org_url="${AZ_DEVOPS_ORG_URL:-}"
project_name="${AZ_DEVOPS_PROJECT:-}"
location="${AZ_LOCATION:-eastus}"
pat="${AZ_DEVOPS_PAT:-}"

# Input validation for essential variables
if [[ -z "$org_url" ]]; then
    read -p "Enter Azure DevOps Organization URL: " org_url
fi
if [[ -z "$project_name" ]]; then
    read -p "Enter Azure DevOps Project Name: " project_name
fi

# Check if an Azure subscription is already set
current_subscription=$(az account show --query "id" --output tsv 2>/dev/null)
if [[ -z "$current_subscription" ]]; then
    read -s -p "Enter the Azure subscription ID: " subscription_id
    echo ""
    az account set --subscription "$subscription_id"
else
    echo "Using already configured subscription: $current_subscription"
fi

# Extract organization name from URL
org_name=$(echo "$org_url" | sed 's|https://dev.azure.com/||' | sed 's|/.*||')

# Ensure PAT is available
if [[ -z "$pat" ]]; then
    read -s -p "Enter Azure DevOps PAT: " pat
    echo ""
fi

# Prepare Base64 encoded PAT for Git authentication
# Azure DevOps uses an empty username with the PAT as the password
B64_PAT=$(echo -n ":$pat" | base64)

# Configure Azure and Azure DevOps CLI
echo "Configuring Azure CLI and DevOps extension..."
az devops configure --defaults organization="$org_url" project="$project_name"

# Create the resource group
echo "Creating resource group $resource_group in $location..."
az group create --name "$resource_group" --location "$location"

# Check if repository exists
repo_exists=$(az repos show --repository "$repo_name" --project "$project_name" --organization "$org_url" --output tsv --query "name" || echo "not found")

if [[ "$repo_exists" == "$repo_name" ]]; then
    echo "Repository $repo_name already exists, using it."
else
    echo "Creating repository $repo_name..."
    az repos create --name "$repo_name" --project "$project_name" --organization "$org_url"
fi

# Upload some code to the repository
echo "Setting up local repository and adding code..."
temp_dir=$(mktemp -d)
cd "$temp_dir"
git init
git config --local user.email "user@example.com"
git config --local user.name "Azure DevOps Script"

# Create sample Python code
mkdir tests
echo "def test_example(): assert 1 == 1" > tests/test_example.py

# Create requirements.txt with pytest
echo "pytest" > requirements.txt

# Commit and push the code
git add .
git commit -m "Initial commit with test code and requirements"

git remote add origin "https://dev.azure.com/${org_name}/${project_name}/_git/${repo_name}"

echo "Pushing code to repository..."
git -c http.extraheader="Authorization: Basic $B64_PAT" push -u origin master

# Create azure-pipelines.yml file dynamically
echo "Creating azure-pipelines.yml file..."

cat <<EOL > azure-pipelines.yml
trigger:
- master  # This can be changed to any branch you want to trigger the pipeline from

pool:
  vmImage: 'ubuntu-latest'  # Using Ubuntu for the build agent

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.x'  # Specify the version of Python you need, for example, 3.x
    addToPath: true

- script: |
    python -m venv venv  # Create a virtual environment
    source venv/bin/activate  # Activate the virtual environment
    pip install -r requirements.txt  # Install dependencies from requirements.txt
  displayName: 'Install dependencies'

- script: |
    python tests/test_example.py  # Run the tests using pytest
  displayName: 'Run tests with pytest'
EOL

# Add the azure-pipelines.yml file to the repository
git add azure-pipelines.yml
git commit -m "Add azure-pipelines.yml for CI pipeline"

# Push the changes (including the YAML file) to the repository securely
git -c http.extraheader="Authorization: Basic $B64_PAT" push

# Step 6: Ensure the pipeline exists
echo "Checking if pipeline '$pipeline_name' exists..."
pipeline_exists=$(az pipelines list --name "$pipeline_name" --project "$project_name" --organization "$org_url" --query "[].id" --output tsv)

if [ -z "$pipeline_exists" ]; then
    echo "Creating new pipeline: $pipeline_name..."
    az pipelines create --name "$pipeline_name" --repository "$repo_name" --repository-type tfsgit --branch master --yml-path azure-pipelines.yml --project "$project_name" --organization "$org_url"
else
    echo "Pipeline '$pipeline_name' already exists."
fi

# Trigger the pipeline run
pipeline_id=$(az pipelines list --name "$pipeline_name" --project "$project_name" --organization "$org_url" --query "[].id" --output tsv)
az pipelines run --name $pipeline_name --project $project_name --organization $org_url

# Clean up temporary directory
cd "$OLDPWD"
rm -rf "$temp_dir"

echo "Setup completed successfully!"
echo "Resource Group: $resource_group"
echo "Repository: $repo_name"
echo "Pipeline: $pipeline_name"
