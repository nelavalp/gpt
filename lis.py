import requests
import json

# vCenter Server details
VCENTER_SERVER = "your-vcenter-server"
USERNAME = "your-username"
PASSWORD = "your-password"

# Authenticate and obtain an authentication token
auth_url = f"https://{VCENTER_SERVER}/api/vcenter/authentication/token"
auth_payload = {
    "username": USERNAME,
    "password": PASSWORD
}
auth_headers = {
    "Content-Type": "application/json"
}

response = requests.post(auth_url, headers=auth_headers, json=auth_payload, verify=False)
auth_token = response.json()["access_token"]

# Check if authentication is successful
if not auth_token:
    print("Authentication failed. Check your credentials or vCenter Server details.")
    exit(1)

# Function to get datastore ID from its name
def get_datastore_id(datastore_name):
    datastore_url = f"https://{VCENTER_SERVER}/rest/vcenter/datastore"
    headers = {
        "Content-Type": "application/json",
        "vmware-api-session-id": auth_token
    }
    response = requests.get(datastore_url, headers=headers, verify=False)
    datastores = response.json()["value"]
    for datastore in datastores:
        if datastore["name"] == datastore_name:
            return datastore["datastore"]

# Function to list VMs associated with a datastore
def list_vms_for_datastore(datastore_id):
    vm_url = f"https://{VCENTER_SERVER}/rest/vcenter/vm?filter.datastores={datastore_id}"
    headers = {
        "Content-Type": "application/json",
        "vmware-api-session-id": auth_token
    }
    response = requests.get(vm_url, headers=headers, verify=False)
    vms = response.json()["value"]
    for vm in vms:
        print(f"VM Name: {vm['name']}, Power State: {vm['power_state']}, Guest OS: {vm['guest']['os_type']}, Guest IP: {vm['guest']['ip_address']}")

# Function to list all VMs in the vSphere environment
def list_all_vms():
    vm_url = f"https://{VCENTER_SERVER}/rest/vcenter/vm"
    headers = {
        "Content-Type": "application/json",
        "vmware-api-session-id": auth_token
    }
    response = requests.get(vm_url, headers=headers, verify=False)
    vms = response.json()["value"]
    for vm in vms:
        print(f"VM Name: {vm['name']}, Power State: {vm['power_state']}, Guest OS: {vm['guest']['os_type']}, Guest IP: {vm['guest']['ip_address']}")

# Main function to list VMs for each datastore and all VMs
def main():
    # Header for CSV
    print("Datastore,VM Name,Power State,Guest OS,Guest IP")

    # Get list of datastores
    datastore_names = ["datastore1", "datastore2"]  # Replace with your datastore names
    for datastore_name in datastore_names:
        datastore_id = get_datastore_id(datastore_name)
        list_vms_for_datastore(datastore_id)

    # List all VMs
    list_all_vms()

# Execute the main function
main()

# Logout
logout_url = f"https://{VCENTER_SERVER}/api/vcenter/authentication/session"
headers = {
    "Content-Type": "application/json",
    "vmware-api-session-id": auth_token
}
response = requests.delete(logout_url, headers=headers, verify=False)
