#!/bin/bash

# vCenter Server details
VCENTER_SERVER="your-vcenter-server"
USERNAME="your-username"
PASSWORD="your-password"

# Output CSV file
OUTPUT_CSV="output.csv"

# Function to authenticate and obtain a session ID
get_session_id() {
  curl -s -k -X POST "https://${VCENTER_SERVER}/rest/com/vmware/cis/session" -u "${USERNAME}:${PASSWORD}" | jq -r .value
}

# Function to list VMs and append to CSV
list_vms() {
  local session_id="$1"
  local datastore_name="$2"
  curl -s -k -X GET -H "vmware-api-session-id: ${session_id}" "https://${VCENTER_SERVER}/rest/vcenter/vm" | \
  jq -r --arg datastore "$datastore_name" '.value[] | "\($datastore),\(.name),\(.power_state)"'
}

# Main function to list VMs for each datastore and append to CSV
main() {
  # Get session ID
  session_id=$(get_session_id)

  # Check if session ID is obtained
  if [ -z "$session_id" ]; then
    echo "Failed to obtain session ID. Check your credentials or vCenter Server details."
    exit 1
  fi

  # Create CSV file with header
  echo "Datastore,VM Name,Power State" > "$OUTPUT_CSV"

  # Read datastore names from a file
  while IFS= read -r datastore; do
    while IFS= read -r line; do
      echo "${datastore},${line}"
    done < <(list_vms "$session_id" "$datastore") >> "$OUTPUT_CSV"
  done < datastores.txt  # Change this to your file containing datastore names
}

# Execute the main function
main
