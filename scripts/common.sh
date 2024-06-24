#!/bin/bash

LOG_FILE="/vagrant/logs/common.log"
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

log "INFO" "Starting common.sh script..." $BLUE

# Load settings from environment variables
MASTER_IP=${MASTER_IP}
CNI_CALICO=${CNI_CALICO}
METRICS_SERVER=${METRICS_SERVER}
K8S_VERSION=${K8S_VERSION}

# Function to wait for dpkg lock to be released
wait_for_dpkg_lock() {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    log "WARN" "Waiting for dpkg lock to be released..." $YELLOW
    sleep 5
  done
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    log "WARN" "Waiting for dpkg lock-frontend to be released..." $YELLOW
    sleep 5
  done
}

# Disable swap to meet Kubernetes requirements
disable_swap() {
  log "INFO" "Disabling swap..." $BLUE
  sudo swapoff -a
  sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

# Load necessary kernel modules for Kubernetes
load_kernel_modules() {
  log "INFO" "Loading kernel modules..." $BLUE
  sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
  sudo modprobe overlay
  sudo modprobe br_netfilter
}

# Set kernel parameters required by Kubernetes
set_kernel_parameters() {
  log "INFO" "Setting kernel parameters..." $BLUE
  sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
  sudo sysctl --system
}

# Install essential dependencies
install_dependencies() {
  wait_for_dpkg_lock
  log "INFO" "Installing dependencies..." $BLUE
  sudo apt update
  sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
}

# Add Docker's official GPG key and set up the stable repository
enable_docker_repo() {
  wait_for_dpkg_lock
  log "INFO" "Adding Docker GPG key and repository..." $BLUE
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null""
}

# Install Docker
install_docker() {
  wait_for_dpkg_lock
  log "INFO" "Installing Docker..." $BLUE
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
}

# Install and configure containerd
install_containerd() {
  wait_for_dpkg_lock
  log "INFO" "Installing containerd..." $BLUE
  sudo apt update
  sudo apt install -y containerd
  sudo mkdir -p /etc/containerd
  sudo containerd config default | sudo tee /etc/containerd/config.toml
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
  sudo systemctl restart containerd
  sudo systemctl enable containerd
}

# Add Kubernetes apt repository and its GPG key
setup_kubernetes_repo() {
  wait_for_dpkg_lock
  log "INFO" "Setting up Kubernetes repository..." $BLUE
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

# Install Kubernetes components: kubelet, kubeadm, and kubectl
install_kubernetes_components() {
  wait_for_dpkg_lock
  log "INFO" "Installing Kubernetes components..." $BLUE
  sudo apt update
  sudo apt install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl
}

initialize_kubernetes_environment() {
  disable_swap
  load_kernel_modules
  set_kernel_parameters
  install_dependencies
  enable_docker_repo
  install_docker
  install_containerd
  setup_kubernetes_repo
  install_kubernetes_components
}

log "INFO" "Finished common.sh script." $BLUE
