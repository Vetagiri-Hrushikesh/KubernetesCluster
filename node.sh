#!/bin/bash

source /vagrant/common.sh

join_kubernetes_cluster() {
  if [ -f /vagrant/configs/join.sh ]; then
    sudo bash /vagrant/configs/join.sh
  else
    echo "Join script not found. Ensure the master node is provisioned and the join script is generated."
  fi
}

# Main script
join_kubernetes_cluster
