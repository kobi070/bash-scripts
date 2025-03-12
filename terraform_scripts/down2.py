import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.resource import ResourceManagementClient

print("Deleting Azure resources... This may take a few minutes.")

# Acquire a credential object
credential = DefaultAzureCredential()

# Retrieve subscription ID from environment variable
subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]

# Resource names
RESOURCE_GROUP_NAME = "Kobi-VM-rg"
VNET_NAME = "python-kobi-vnet"
SUBNET_NAME = "python-kobi-subnet"
IP_NAME = "python-kobi-ip"
NIC_NAME = "python-kobi-nic"
VM_NAME = "ExampleVM"

# Initialize clients
resource_client = ResourceManagementClient(credential, subscription_id)


# Step 1: Delete the resource group (which deletes all remaining resources inside it)
try:
    print(f"Deleting resource group {RESOURCE_GROUP_NAME}...")
    resource_client.resource_groups.begin_delete(RESOURCE_GROUP_NAME).result()
    print(f"Deleted resource group {RESOURCE_GROUP_NAME}")
except Exception as e:
    print(f"Error deleting resource group: {e}")

print("All specified resources have been deleted.")
