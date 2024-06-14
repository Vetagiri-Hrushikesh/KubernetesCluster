#!/bin/bash

LOG_FILE="/vagrant/logs/master.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

source /vagrant/scripts/common.sh

log "INFO" "Starting master.sh script..." $BLUE

initialize_kubernetes_master() {
  log "INFO" "Initializing Kubernetes master node..." $BLUE
  sudo kubeadm init --control-plane-endpoint=$MASTER_HOSTNAME

  log "INFO" "Setting up kubeconfig for the root user..." $BLUE
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  export KUBECONFIG=$HOME/.kube/config
  cp $HOME/.kube/config /vagrant/configs/

}

save_join_command() {
  local config_path="/vagrant/configs"

  log "INFO" "Saving join command for worker nodes..." $BLUE
  mkdir -p $config_path
  kubeadm token create --print-join-command > $config_path/join.sh
  chmod +x $config_path/join.sh

  log "INFO" "Master is ready, and the join command is saved to /vagrant/configs/join.sh" $GREEN
}

install_network_plugin() {
  log "INFO" "Installing Calico network plugin..." $BLUE
  kubectl apply -f $CNI_CALICO
}

setup_vagrant_user_kubectl() {
  log "INFO" "Setting up kubeconfig for the vagrant user..." $BLUE
  sudo -i -u vagrant bash <<EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
echo "alias k='kubectl'" >> ~/.bashrc
EOF
}

install_metrics_server() {
  log "INFO" "Installing metrics server..." $BLUE
  kubectl apply -f $METRICS_SERVER
}

initialize_kubernetes_environment
initialize_kubernetes_master
save_join_command
install_network_plugin
setup_vagrant_user_kubectl
install_metrics_server

log "INFO" "Finished master.sh script." $BLUE
