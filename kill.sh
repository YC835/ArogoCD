#!/bin/bash

set -e

echo "=============================="
echo "Installing required packages"
echo "=============================="

apt-get update -y
apt-get install -y tree git curl wget

echo
echo "=============================="
echo "Clone Repository"
echo "=============================="

cd /root

if [ ! -d ArogoCD ]; then
    git clone https://github.com/YC835/ArogoCD.git
fi

cd /root/ArogoCD

echo
echo "=============================="
echo "Install Argo CD"
echo "=============================="

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply --server-side \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo
echo "=============================="
echo "Waiting for Argo CD"
echo "=============================="

kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

kubectl rollout status deployment/argocd-server -n argocd --timeout=600s

kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=600s

kubectl rollout status deployment/argocd-applicationset-controller -n argocd --timeout=600s

kubectl rollout status deployment/argocd-dex-server -n argocd --timeout=600s

kubectl rollout status deployment/argocd-notifications-controller -n argocd --timeout=600s

echo
echo "=============================="
echo "Enable HTTP mode"
echo "=============================="

# kubectl patch configmap argocd-cmd-params-cm \
# -n argocd \
# --type merge \
# -p '{"data":{"server.insecure":"true"}}'

# kubectl rollout restart deployment argocd-server -n argocd

# kubectl rollout status deployment argocd-server -n argocd --timeout=300s

echo
echo "=============================="
echo "Admin Password"
echo "=============================="

kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d

echo
echo
echo "=============================="
echo "Start Port Forward"
echo "=============================="

echo
echo "Run the command below in another terminal:"
echo
echo "kubectl port-forward svc/argocd-server -n argocd 9090:80 --address 0.0.0.0"
echo
echo "Expose Port 9090 in Killercoda."
echo
echo "Open:"
echo
echo "http://<killercoda-session>-9090....killercoda.com"
