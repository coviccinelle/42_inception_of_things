#!/bin/bash

SERVER_IP="192.168.56.110"

# 1.Take secure TOKEN from Server through inter-SHH (Vagrant auto config)
# take cat command directly via Server's IP
TOKEN=$(ssh -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_rsa vagrant@$SERVER_IP "sudo cat /var/lib/rancher/k3s/server/node-token")

# 2.setting K3s in Agent mode (worker) and connect to Server
curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1" sh -

echo " === Setting up K3s Worker done, connected to Master done! ==="
