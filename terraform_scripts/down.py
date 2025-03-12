#!/usr/bin/env python

import os
from azure.identity import ClientSecretCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.resource import ResourceManagementClient

print("Deleting Azure resources... This may take a few minutes.")

# Retrieve subscription ID from environment variable.
subscription_id = os.environ["AZURE_SUBSCRIPTION_ID"]
app_id = os.environ["AZURE_CLIENT_ID"]
app_secret = os.environ["AZURE_CLIENT_SECRET"]
tenant_id = os.environ["AZURE_TENANT_ID"]

# Acquire a credential object.
credential = ClientSecretCredential(
    client_id=app_id, client_secret=app_secret, tenant_id=tenant_id
)

# Resource names
RESOURCE_GROUP_NAME = "Kobi-VM-rg"
VNET_NAME = "python-kobi-vnet"
SUBNET_NAME = "python-kobi-subnet"
IP_NAME = "python-kobi-ip"
NIC_NAME = "python-kobi-nic"
VM_NAME = "KobiVM"

# Initialize clients
resource_client = ResourceManagementClient(credential, subscription_id)
network_client = NetworkManagementClient(credential, subscription_id)
compute_client = ComputeManagementClient(credential, subscription_id)

# Step 1: Delete the virtual machine
try:
    print(f"Deleting virtual machine {VM_NAME}...")
    compute_client.virtual_machines.begin_delete(RESOURCE_GROUP_NAME, VM_NAME).result()
    print(f"Deleted virtual machine {VM_NAME}")
except Exception as e:
    print(f"Error deleting virtual machine: {e}")

# Step 2: Delete the network interface
try:
    print(f"Deleting network interface {NIC_NAME}...")
    network_client.network_interfaces.begin_delete(RESOURCE_GROUP_NAME, NIC_NAME).result()
    print(f"Deleted network interface {NIC_NAME}")
except Exception as e:
    print(f"Error deleting network interface: {e}")

# Step 3: Delete the public IP
try:
    print(f"Deleting public IP address {IP_NAME}...")
    network_client.public_ip_addresses.begin_delete(RESOURCE_GROUP_NAME, IP_NAME).result()
    print(f"Deleted public IP address {IP_NAME}")
except Exception as e:
    print(f"Error deleting public IP address: {e}")

# Step 4: Delete the virtual network
try:
    print(f"Deleting virtual network {VNET_NAME}...")
    network_client.virtual_networks.begin_delete(RESOURCE_GROUP_NAME, VNET_NAME).result()
    print(f"Deleted virtual network {VNET_NAME}")
except Exception as e:
    print(f"Error deleting virtual network: {e}")

# Step 5: Delete the resource group (which deletes all remaining resources inside it)
try:
    print(f"Deleting resource group {RESOURCE_GROUP_NAME}...")
    resource_client.resource_groups.begin_delete(RESOURCE_GROUP_NAME).result()
    print(f"Deleted resource group {RESOURCE_GROUP_NAME}")
except Exception as e:
    print(f"Error deleting resource group: {e}")

print("All specified resources have been deleted.")
