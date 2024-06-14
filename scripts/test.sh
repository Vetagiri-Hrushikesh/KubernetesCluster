#!/bin/bash

LOG_FILE="/vagrant/logs/test.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

# Define color codes
RESET="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"

# Logging function with levels
log() {
  local level=$1
  local message=$2
  local color=$3

  echo -e "${color}$(date '+%Y-%m-%d %H:%M:%S') - [$level] - $message${RESET}"
}

log "INFO" "Starting test.sh script..." $BLUE

cd /vagrant/configs || { log "ERROR" "Failed to change directory to /vagrant/configs" $RED; exit 1; }
log "INFO" "Changed directory to /vagrant/configs" $BLUE

sudo chmod +r config || { log "ERROR" "Failed to change permissions of config file" $RED; exit 1; }
log "INFO" "Changed permissions of config file" $BLUE

export KUBECONFIG=$(pwd)/config
log "INFO" "Set KUBECONFIG to $(pwd)/config" $BLUE

kubectl get pods -n kube-system || { log "ERROR" "Failed to get pods in kube-system namespace" $RED; exit 1; }
log "INFO" "Retrieved pods in kube-system namespace" $GREEN

kubectl get nodes || { log "ERROR" "Failed to get nodes" $RED; exit 1; }
log "INFO" "Retrieved nodes" $GREEN

log "INFO" "Finished test.sh script." $BLUE
