import os
import subprocess
import tempfile
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.devops.connection import Connection
from azure.devops.v6_0.git.git_client import GitClient
from azure.devops.v6_0.pipelines.pipelines_client import PipelinesClient
from msrest.authentication import BasicAuthentication

# Azure DevOps configuration
org_url = "https://dev.azure.com/markveltzer"
project_name = "training"
pat = "EXysGY6nOWBETGkJNovT9vkeSAxLdoDp1uPYrCRgB2uospP7IVY7JQQJ99BCACAAAAAAAAAAAAASAZDO0Tu4"
org_name = org_url.replace("https://dev.azure.com/", "")

# Authenticate using a Personal Access Token (PAT) for Azure DevOps
credentials = BasicAuthentication("", pat)
connection = Connection(base_url=org_url, creds=credentials)

# Azure Resource Manager setup
subscription_id = input("Enter the Azure subscription ID: ")
credential = DefaultAzureCredential()
resource_client = ResourceManagementClient(credential, subscription_id)

# Ask for user input
repo_name = input("Enter the name for the repository: ")
pipeline_name = input("Enter the name for the pipeline: ")
resource_group = input("Enter the name of the resource group: ")

location = "eastus"

# Create resource group
print(f"Creating resource group {resource_group} in {location}...")
resource_group_params = {
    "location": location
}
resource_client.resource_groups.create_or_update(resource_group, resource_group_params)

# Set up a temporary directory
with tempfile.TemporaryDirectory() as temp_dir:
    os.chdir(temp_dir)

    # Initialize Git Client
    git_client = connection.clients.get_git_client()

    # Check if repository exists
    repos = git_client.get_repositories(project=project_name)
    repo_exists = any(repo.name == repo_name for repo in repos)

    if repo_exists:
        print(f"Repository {repo_name} already exists, cloning it into temp directory.")
        subprocess.run(["git", "clone", f"https://{pat}@dev.azure.com/{org_name}/{project_name}/_git/{repo_name}"])
        os.chdir(repo_name)
    else:
        print(f"Creating repository {repo_name}...")
        git_client.create_repository(project=project_name, repository_name=repo_name)
        print("Setting up local repository and adding code...")

        subprocess.run(["git", "init"])
        subprocess.run(["git", "config", "--local", "user.email", "user@example.com"])
        subprocess.run(["git", "config", "--local", "user.name", "Azure DevOps Script"])

        # Create sample Python code
        os.makedirs("tests", exist_ok=True)
        with open("tests/test_example.py", "w") as f:
            f.write("def test_example(): assert 1 == 1")

        # Create requirements.txt with pytest
        with open("requirements.txt", "w") as f:
            f.write("pytest")

        # Commit and push the code
        subprocess.run(["git", "add", "."])
        subprocess.run(["git", "commit", "-m", "Initial commit with test code and requirements"])
        subprocess.run(["git", "remote", "add", "origin", f"https://{pat}@dev.azure.com/{org_name}/{project_name}/_git/{repo_name}"])
        subprocess.run(["git", "push", "-u", "origin", "master"])

    # Check if azure-pipelines.yml already exists
    if not os.path.isfile("azure-pipelines.yml"):
        print("Creating azure-pipelines.yml file...")
        with open("azure-pipelines.yml", "w") as f:
            f.write("""
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
            """)

        subprocess.run(["git", "add", "azure-pipelines.yml"])
        subprocess.run(["git", "commit", "-m", "Add azure-pipelines.yml for CI pipeline"])
        subprocess.run(["git", "push"])
    else:
        print("azure-pipelines.yml already exists. Skipping creation.")

    # Ensure the pipeline exists
    pipelines_client = connection.clients.get_pipelines_client()

    print(f"Checking if pipeline '{pipeline_name}' exists...")
    pipelines = pipelines_client.list_pipelines(project=project_name)
    pipeline_exists = any(pipeline.name == pipeline_name for pipeline in pipelines)

    if not pipeline_exists:
        print(f"Creating new pipeline: {pipeline_name}...")
        pipelines_client.create_pipeline(
            project=project_name,
            definition={"name": pipeline_name, "repository": {"id": repo_name, "type": "tfsgit"}, "ymlPath": "azure-pipelines.yml"}
        )
    else:
        print(f"Pipeline '{pipeline_name}' already exists.")

    # Trigger the pipeline run
    print(f"Triggering the pipeline '{pipeline_name}'...")
    pipeline = next(pipeline for pipeline in pipelines if pipeline.name == pipeline_name)
    pipelines_client.run_pipeline(pipeline.id)

print("Setup completed successfully!")
print(f"Resource Group: {resource_group}")
print(f"Repository: {repo_name}")
print(f"Pipeline: {pipeline_name}")
