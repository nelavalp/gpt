#!/bin/bash

# vCenter Server details
VCENTER_SERVER="your-vcenter-server"
USERNAME="your-username"
PASSWORD="your-password"

# Function to authenticate and obtain an authentication token
authenticate() {
  local auth_token
  auth_token=$(curl -s -k -X POST -H "Content-Type: application/json" -d '{"username":"'${USERNAME}'","password":"'${PASSWORD}'"}' "https://${VCENTER_SERVER}/api/vcenter/authentication/token" | jq -r .access_token)
  echo "$auth_token"
}

# Function to get datastore ID from its name
get_datastore_id() {
  local datastore_name="$1"
  curl -s -k -X GET -H "Content-Type: application/json" -H "vmware-api-session-id: ${auth_token}" "https://${VCENTER_SERVER}/rest/vcenter/datastore" | jq -r '.value[] | select(.name == "'${datastore_name}'") | .datastore'
}

# Function to list VMs associated with a datastore
list_vms_for_datastore() {
  local datastore_id="$1"
  curl -s -k -X GET -H "Content-Type: application/json" -H "vmware-api-session-id: ${auth_token}" "https://${VCENTER_SERVER}/rest/vcenter/vm?filter.datastores=${datastore_id}" | jq -r '.value[] | [.name, .power_state, .guest.os_type, .guest.ip_address] | @csv'
}

# Function to list all VMs in the vSphere environment
list_all_vms() {
  curl -s -k -X GET -H "Content-Type: application/json" -H "vmware-api-session-id: ${auth_token}" "https://${VCENTER_SERVER}/rest/vcenter/vm" | jq -r '.value[] | [.name, .power_state, .guest.os_type, .guest.ip_address] | @csv'
}

# Main function to list VMs for each datastore and all VMs
main() {
  # Authenticate and obtain an authentication token
  auth_token=$(authenticate)

  # Check if authentication is successful
  if [ -z "$auth_token" ]; then
    echo "Authentication failed. Check your credentials or vCenter Server details."
    exit 1
  fi

  # Header for CSV
  echo "Datastore,VM Name,Power State,Guest OS,Guest IP"

  # Read datastore names from a text file
  while IFS= read -r datastore; do
    datastore_id=$(get_datastore_id "$datastore")
    list_vms_for_datastore "$datastore_id" | sed "s/^/${datastore},/"
  done < datastores.txt  # Change this to your text file containing datastore names

  # List all VMs
  list_all_vms
}

# Execute the main function and save CSV values to a file
main > output.csv
