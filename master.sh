#!/bin/bash

source /vagrant/common.sh

initialize_kubernetes_master() {
  sudo kubeadm init --control-plane-endpoint=$MASTER_HOSTNAME

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  export KUBECONFIG=$HOME/.kube/config
}

save_join_command() {
  local config_path="/vagrant/configs"

  if [ -d $config_path ]; then
    rm -f $config_path/*
  else
    mkdir -p $config_path
  fi

  cp -i /etc/kubernetes/admin.conf $config_path/config
  kubeadm token create --print-join-command > $config_path/join.sh
  chmod +x $config_path/join.sh

  echo "Master is ready, and the join command is saved to /vagrant/configs/join_master.sh"
}

install_network_plugin() {
  kubectl apply -f $CNI_CALICO
}

setup_vagrant_user_kubectl() {
  sudo -i -u vagrant bash <<EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
echo "alias k='kubectl'" >> ~/.bashrc
EOF
}

install_metrics_server() {
  kubectl apply -f $METRICS_SERVER
}

# # Main script
initialize_kubernetes_master
save_join_command
install_network_plugin
setup_vagrant_user_kubectl
install_metrics_server
