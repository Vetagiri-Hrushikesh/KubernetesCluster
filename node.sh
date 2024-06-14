#!/bin/bash

# Source the common script for shared functions
source /vagrant/common.sh

# Function to join the Kubernetes cluster
join_kubernetes_cluster() {
  # Check if the join script exists
  if [ -f /vagrant/configs/join.sh ]; then
    # Execute the join script to add this node to the cluster
    sudo bash /vagrant/configs/join.sh
  else
    # Print an error message if the join script is not found
    echo "Join script not found. Ensure the master node is provisioned and the join script is generated."
  fi
}

# Main script execution
join_kubernetes_cluster
