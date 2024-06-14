#!/bin/bash
#
# Deploys the Kubernetes dashboard when enabled in settings.yaml

LOG_FILE="/vagrant/logs/dashboard.log"
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

log "INFO" "Starting dashboard.sh script..." $BLUE

DASHBOARD_VERSION=${DASHBOARD_VERSION:-"v2.7.0"}

install_dashboard() {
  while sudo -i -u vagrant kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'Waiting for metrics server to be ready...'
    sleep 5
  done

  echo 'Metrics server is ready. Installing dashboard...'

  sudo -i -u vagrant kubectl create namespace kubernetes-dashboard

  echo "Creating the dashboard user..."

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

  echo "Deploying the dashboard..."
  sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml"

  sudo -i -u vagrant kubectl -n kubernetes-dashboard get secret/admin-user -o go-template="{{.data.token | base64decode}}" > "/vagrant/logs/dashboard_token"
  echo "The following token was also saved to: /vagrant/logs/dashboard_token"
  cat "/vagrant/logs/dashboard_token"

  # Patch the service to be of type NodePort
  sudo -i -u vagrant kubectl -n kubernetes-dashboard patch service kubernetes-dashboard --patch '{"spec": {"type": "NodePort"}}'
  log "INFO" "Kubernetes proxy started. You can access the dashboard at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard"
}

install_dashboard

log "INFO" "Finished dashboard.sh script." $BLUE
