#!/bin/bash

# Function to wait for dpkg lock release
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

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Set kernel parameters
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Wait for dpkg lock to be released
wait_for_dpkg_lock

# Install dependencies
sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Enable Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64,arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Wait for dpkg lock to be released
wait_for_dpkg_lock

# Install containerd
sudo apt update
sudo apt install -y containerd

# Configure containerd to use systemd as cgroup
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Create the directory for keyrings
sudo mkdir -p /etc/apt/keyrings

# Add the GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Create the Kubernetes repository configuration file
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Wait for dpkg lock to be released
wait_for_dpkg_lock

# Update package lists
sudo apt update

# Install Kubernetes components
sudo apt install -y kubelet kubeadm kubectl

# Hold Kubernetes components at current version
sudo apt-mark hold kubelet kubeadm kubectl

# No need to join the cluster here, this will be handled after the master is ready
