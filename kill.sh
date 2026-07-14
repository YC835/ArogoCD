#!/bin/bash

set -euo pipefail

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
echo "Waiting for Argo CD resources to be created"
echo "=============================="

until kubectl get statefulset argocd-application-controller -n argocd >/dev/null 2>&1; do
    echo "Waiting for StatefulSet..."
    sleep 2
done

until kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; do
    echo "Waiting for argocd-server..."
    sleep 2
done

until kubectl get deployment argocd-repo-server -n argocd >/dev/null 2>&1; do
    echo "Waiting for argocd-repo-server..."
    sleep 2
done

until kubectl get deployment argocd-applicationset-controller -n argocd >/dev/null 2>&1; do
    echo "Waiting for argocd-applicationset-controller..."
    sleep 2
done

until kubectl get deployment argocd-dex-server -n argocd >/dev/null 2>&1; do
    echo "Waiting for argocd-dex-server..."
    sleep 2
done

until kubectl get deployment argocd-notifications-controller -n argocd >/dev/null 2>&1; do
    echo "Waiting for argocd-notifications-controller..."
    sleep 2
done

echo
echo "=============================="
echo "Waiting for Argo CD rollout"
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

kubectl patch configmap argocd-cmd-params-cm \
-n argocd \
--type merge \
-p '{"data":{"server.insecure":"true"}}'

kubectl rollout restart deployment argocd-server -n argocd

kubectl rollout status deployment argocd-server -n argocd --timeout=300s

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

nohup kubectl port-forward svc/argocd-server \
-n argocd \
9090:80 \
--address 0.0.0.0 \
>/tmp/argocd-port-forward.log 2>&1 &

sleep 3

if pgrep -f "kubectl port-forward.*argocd-server" >/dev/null; then
    echo "✓ Port-forward started successfully."
else
    echo "✗ Port-forward failed."
    cat /tmp/argocd-port-forward.log
    exit 1
fi

echo
echo "=============================="
echo "Access Argo CD"
echo "=============================="

echo "URL:"
echo "http://<killercoda-session>-9090....killercoda.com"

echo
echo "Username: admin"
echo "Password: (shown above)"
