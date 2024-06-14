#!/bin/bash

# Source the common script for shared functions
source /vagrant/common.sh

# Initialize the Kubernetes master node
initialize_kubernetes_master() {
  sudo kubeadm init --control-plane-endpoint=$MASTER_HOSTNAME

  # Setup kubeconfig for the root user
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  export KUBECONFIG=$HOME/.kube/config
}

# Save the join command for worker nodes
save_join_command() {
  local config_path="/vagrant/configs"

  # Ensure the configs directory exists and is clean
  if [ -d $config_path ]; then
    rm -f $config_path/*
  else
    mkdir -p $config_path
  fi

  # Copy the admin config and generate the join command
  cp -i /etc/kubernetes/admin.conf $config_path/config
  kubeadm token create --print-join-command > $config_path/join.sh
  chmod +x $config_path/join.sh

  echo "Master is ready, and the join command is saved to /vagrant/configs/join_master.sh"
}

# Install the Calico network plugin
install_network_plugin() {
  kubectl apply -f $CNI_CALICO
}

# Setup kubeconfig for the vagrant user
setup_vagrant_user_kubectl() {
  sudo -i -u vagrant bash <<EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
echo "alias k='kubectl'" >> ~/.bashrc
EOF
}

# Install the metrics server
install_metrics_server() {
  kubectl apply -f $METRICS_SERVER
}

# Main script execution
initialize_kubernetes_master
save_join_command
install_network_plugin
setup_vagrant_user_kubectl
install_metrics_server
