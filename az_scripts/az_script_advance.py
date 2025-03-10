import os
import subprocess
import tempfile

# Ask the user for input values
repo_name = input("Enter the name for the repository: ")
pipeline_name = input("Enter the name for the pipeline: ")
resource_group = input("Enter the name of the resource group: ")

org_url = "https://dev.azure.com/markveltzer"
project_name = "training"
location = "eastus"
pat = "EXysGY6nOWBETGkJNovT9vkeSAxLdoDp1uPYrCRgB2uospP7IVY7JQQJ99BCACAAAAAAAAAAAAASAZDO0Tu4"

# Check if an Azure subscription is already set
try:
    current_subscription = subprocess.check_output(
        ["az", "account", "show", "--query", "id", "--output", "tsv"],
        stderr=subprocess.PIPE
    ).decode().strip()
except subprocess.CalledProcessError:
    current_subscription = None

if current_subscription is None:
    subscription_id = input("Enter the Azure subscription ID: ")
    subprocess.run(["az", "account", "set", "--subscription", subscription_id])
else:
    print(f"Using already configured subscription: {current_subscription}")

# Extract organization name from URL
org_name = org_url.replace("https://dev.azure.com/", "")

# Configure Azure and Azure DevOps CLI
print("Configuring Azure CLI and DevOps extension...")
subprocess.run(["az", "devops", "configure", "--defaults", f"organization={org_url}", f"project={project_name}"])

# Create the resource group
print(f"Creating resource group {resource_group} in {location}...")
subprocess.run(["az", "group", "create", "--name", resource_group, "--location", location])

# Check if repository exists
try:
    repo_exists = subprocess.check_output(
        ["az", "repos", "show", "--repository", repo_name, "--project", project_name, "--organization", org_url, "--output", "tsv", "--query", "name"],
        stderr=subprocess.PIPE
    ).decode().strip()
except subprocess.CalledProcessError:
    repo_exists = "not found"

# Set up a temporary directory
with tempfile.TemporaryDirectory() as temp_dir:
    os.chdir(temp_dir)

    if repo_exists == repo_name:
        print(f"Repository {repo_name} already exists, cloning it into temp directory.")
        subprocess.run(["git", "clone", f"https://{pat}@dev.azure.com/{org_name}/{project_name}/_git/{repo_name}"])
        os.chdir(repo_name)
    else:
        print(f"Creating repository {repo_name}...")
        subprocess.run(["az", "repos", "create", "--name", repo_name, "--project", project_name, "--organization", org_url])
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
    print(f"Checking if pipeline '{pipeline_name}' exists...")
    try:
        pipeline_exists = subprocess.check_output(
            ["az", "pipelines", "list", "--name", pipeline_name, "--project", project_name, "--organization", org_url, "--query", "[].id", "--output", "tsv"],
            stderr=subprocess.PIPE
        ).decode().strip()
    except subprocess.CalledProcessError:
        pipeline_exists = ""

    if not pipeline_exists:
        print(f"Creating new pipeline: {pipeline_name}...")
        subprocess.run([
            "az", "pipelines", "create", "--name", pipeline_name, "--repository", repo_name, "--repository-type", "tfsgit", "--branch", "master",
            "--yml-path", "azure-pipelines.yml", "--project", project_name, "--organization", org_url
        ])
    else:
        print(f"Pipeline '{pipeline_name}' already exists.")

    # Trigger the pipeline run
    subprocess.run(["az", "pipelines", "run", "--name", pipeline_name, "--project", project_name, "--organization", org_url])

print("Setup completed successfully!")
print(f"Resource Group: {resource_group}")
print(f"Repository: {repo_name}")
print(f"Pipeline: {pipeline_name}")
