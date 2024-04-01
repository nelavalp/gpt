#!/bin/bash

# vCenter Server details
VCENTER_SERVER="your-vcenter-server"
USERNAME="your-username"
PASSWORD="your-password"

# Function to authenticate and obtain a session ID
get_session_id() {
  local session_id
  session_id=$(curl -s -k -X POST "https://${VCENTER_SERVER}/rest/com/vmware/cis/session" -u "${USERNAME}:${PASSWORD}" | jq -r .value)
  echo "$session_id"
}

# Function to get datastore ID from its name
get_datastore_id() {
  local datastore_name="$1"
  curl -s -k -X GET -H "vmware-api-session-id: ${session_id}" "https://${VCENTER_SERVER}/rest/vcenter/datastore" | jq -r '.value[] | select(.name == "'${datastore_name}'") | .datastore'
}

# Function to list VMs associated with a datastore
list_vms_for_datastore() {
  local datastore_id="$1"
  curl -s -k -X GET -H "vmware-api-session-id: ${session_id}" "https://${VCENTER_SERVER}/rest/vcenter/vm?filter.datastores=${datastore_id}" | jq
}

# Main function to list VMs for each datastore
main() {
  # Get session ID
  session_id=$(get_session_id)

  # Check if session ID is obtained
  if [ -z "$session_id" ]; then
    echo "Failed to obtain session ID. Check your credentials or vCenter Server details."
    exit 1
  fi

  # Read datastore names from a file
  while IFS= read -r datastore; do
    datastore_id=$(get_datastore_id "$datastore")
    echo "VMs in datastore: $datastore"
    list_vms_for_datastore "$datastore_id"
    echo ""
  done < datastores.txt  # Change this to your file containing datastore names
}

# Execute the main function
main
