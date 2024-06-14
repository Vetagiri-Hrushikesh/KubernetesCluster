#!/bin/bash

LOG_FILE="/vagrant/logs/node.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

source /vagrant/scripts/common.sh

log "INFO" "Starting node.sh script..." $BLUE

join_kubernetes_cluster() {
  log "INFO" "Attempting to join Kubernetes cluster..." $BLUE
  if [ -f /vagrant/configs/join.sh ]; then
    log "INFO" "Executing join script..." $BLUE
    sudo bash /vagrant/configs/join.sh
  else
    log "ERROR" "Join script not found. Ensure the master node is provisioned and the join script is generated." $RED
    exit 1
  fi
}

initialize_kubernetes_environment
join_kubernetes_cluster

log "INFO" "Finished node.sh script." $BLUE
