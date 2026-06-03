#!/bin/bash
set -e

echo "==> Installation de K3s en mode server..."
curl -sfL https://get.k3s.io | sh -

echo "==> Attente que K3s soit prêt..."
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  sleep 3
done

echo "==> Correction des permissions kubectl..."
chmod 644 /etc/rancher/k3s/k3s.yaml

echo "==> Ajout de KUBECONFIG pour l'utilisateur vagrant..."
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /home/vagrant/.bashrc

echo "==> Application des manifestes..."
kubectl apply -f /home/vagrant/confs/app-one.yaml
kubectl apply -f /home/vagrant/confs/app-two.yaml
kubectl apply -f /home/vagrant/confs/app-three.yaml
kubectl apply -f /home/vagrant/confs/ingress.yaml

echo "==> Cluster prêt !"
kubectl get all
