#!/bin/bash

echo "Installing K3s Agent (Worker)..."

export K3S_TOKEN="IoT-Secret-Token-42"
export INSTALL_K3S_EXEC="agent \
  --server https://192.168.56.110:6443 \
  --node-ip=192.168.56.111"

curl -sfL https://get.k3s.io | sh -

echo " ===> K3s Worker joined the cluster! ==="
