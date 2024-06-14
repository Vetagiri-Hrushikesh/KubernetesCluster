#!/bin/bash

# Run common tasks
source /vagrant/common.sh

# Initialize the Kubernetes cluster
sudo kubeadm init --control-plane-endpoint=k8smaster.learndocker.xyz

# Set up local kubeconfig for the vagrant user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Also set KUBECONFIG environment variable
export KUBECONFIG=$HOME/.kube/config

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh
echo "Master is ready, and the join command is saved to /vagrant/configs/join_master.sh"

# Install Flannel CNI (or any other CNI you prefer)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
sudo -i -u vagrant bash << EOF

whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
echo "alias k='kubectl'" >> ~/.bashrc
EOF

# Install Metrics Server

kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml
