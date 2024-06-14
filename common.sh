#!/bin/bash

# Load settings from environment variables
MASTER_IP=${MASTER_IP}
CNI_CALICO=${CNI_CALICO}
METRICS_SERVER=${METRICS_SERVER}
K8S_VERSION=${K8S_VERSION}

# Function to wait for dpkg lock to be released
wait_for_dpkg_lock() {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "Waiting for dpkg lock to be released..."
    sleep 5
  done
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for dpkg lock-frontend to be released..."
    sleep 5
  done
}

# Disable swap to meet Kubernetes requirements
disable_swap() {
  sudo swapoff -a
  sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
}

# Load necessary kernel modules for Kubernetes
load_kernel_modules() {
  sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
  sudo modprobe overlay
  sudo modprobe br_netfilter
}

# Set kernel parameters required by Kubernetes
set_kernel_parameters() {
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
  sudo apt update
  sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
}

# Add Docker's official GPG key and set up the stable repository
enable_docker_repo() {
  wait_for_dpkg_lock
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
  sudo add-apt-repository "deb [arch=amd64,arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
}

# Install and configure containerd
install_containerd() {
  wait_for_dpkg_lock
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
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

# Install Kubernetes components: kubelet, kubeadm, and kubectl
install_kubernetes_components() {
  wait_for_dpkg_lock
  sudo apt update
  sudo apt install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl
}

# Main script execution
disable_swap
load_kernel_modules
set_kernel_parameters
install_dependencies
enable_docker_repo
install_containerd
setup_kubernetes_repo
install_kubernetes_components
