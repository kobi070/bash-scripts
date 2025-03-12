# Import required libraries
import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.resource import ResourceManagementClient

print("Provisioning a virtual machine...some operations might take a minute or two.")

# Retrieve subscription ID from environment variable.
subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]
app_id = os.environ["AZURE_CLIENT_ID"]
app_secret = os.environ["AZURE_CLIENT_SECRET"]
tenant_id = os.environ["AZURE_TENANT_ID"]

# Acquire a credential object.
credential = DefaultAzureCredential(
    client_id=app_id, client_secret=app_secret, tenant_id=tenant_id
)

# Initialize clients
compute_client = ComputeManagementClient(credential, subscription_id)
network_client = NetworkManagementClient(credential, subscription_id)

# Constants
RESOURCE_GROUP_NAME = "oleg-terraform-rg"
LOCATION = "eastus"
VNET_NAME = "oleg-vnet"
SUBNET_NAME = "oleg-subnet"
NIC_NAME = "oleg-nic"
VM_NAME = "KobiVM"
USERNAME = "azureuser"
PASSWORD = "ChangePa$$w0rd24"

# Step 1: Get the Subnet ID (✅ This is correct)
subnet = network_client.subnets.get(
    RESOURCE_GROUP_NAME, VNET_NAME, SUBNET_NAME
)

# Step 2: Try to Get the Existing Network Interface (NIC) instead of creating a new one
try:
    nic = network_client.network_interfaces.get(
        RESOURCE_GROUP_NAME, NIC_NAME
    )
    print(f"Found existing Network Interface: {nic.id}")
except Exception as e:
    # Handle the case where NIC does not exist (e.g., create it if needed)
    print(f"Network Interface {NIC_NAME} not found, error: {str(e)}")

# Step 3: Provision the Virtual Machine with the Correct NIC ID
print(f"Provisioning virtual machine {VM_NAME}; this operation might take a few minutes.")

poller = compute_client.virtual_machines.begin_create_or_update(
    RESOURCE_GROUP_NAME,
    VM_NAME,
    {
        "location": LOCATION,
        "storage_profile": {
            "image_reference": {
                "publisher": "Canonical",
                "offer": "UbuntuServer",
                "sku": "16.04.0-LTS",
                "version": "latest",
            }
        },
        "hardware_profile": {"vm_size": "Standard_DS1_v2"},
        "os_profile": {
            "computer_name": VM_NAME,
            "admin_username": USERNAME,
            "admin_password": PASSWORD,
        },
        "network_profile": {
            "network_interfaces": [
                {
                    "id": nic.id,  # ✅ Use the correct NIC ID here
                    "properties": {"primary": True},
                }
            ]
        },
    },
)

vm_result = poller.result()
print(f"Provisioned virtual machine {vm_result.name}")
