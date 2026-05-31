#!/bin/bash

#setting up K3s in Server mode (Master)
# disable=traefik to avoid conflicts with Ingress manual installation in Part 2
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1 --disable traefik" sh -

# 2. Wait for K3s to start and create a file with a secured TOKEN
sleep 10

# 3. Copy file kubeconfig) to a common folder so that the Host / Worker can acces if needed
mkdir -p /etc/rancher/k3s
chmod 644 /etc/rancher/k3s/k3s.yaml

echo "==== Done installation K3s Server! ===="
