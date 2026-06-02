#!/bin/bash

echo "Setting up K3s Server (Controller) ..."

export K3S_KUBECONFIG_MODE="644" #sudo like
export K3S_TOKEN="IoT-Secret-Token-42"

# add some flags but eth1 (let k3s auto-recongnize)

export INSTALL_K3S_EXEC="server \
  --bind-address=192.168.56.110 \
  --advertise-address=192.168.56.110 \
  --node-ip=192.168.56.110"

curl -sfL https://get.k3s.io | sh -

echo "==> wait for K3s ... "
sleep 10
echo "==== Done installation K3s Server! ===="
