#!/usr/bin/env bash
#
# Provisioning de la VM iot-dev (root, via Vagrant).
# Installe Vagrant + VirtualBox pour relancer p1/p2 en nested.
# Docker/kubectl/k3d sont installés par p3/scripts/setup.sh.
#
# Idempotent : relançable avec `vagrant provision`.

set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

export DEBIAN_FRONTEND=noninteractive

# Paquets de base
log "apt update + outils de base"
apt-get update -qq
apt-get install -y -qq curl ca-certificates gnupg lsb-release >/dev/null
install -m 0755 -d /etc/apt/keyrings
ok "outils de base installés"

# Vagrant (nested) pour p1 / p2
if command -v vagrant >/dev/null 2>&1; then
  ok "Vagrant déjà présent"
else
  log "Installation de Vagrant"
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
  echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list
  apt-get update -qq
  apt-get install -y -qq vagrant >/dev/null
  ok "Vagrant installé"
fi

# VirtualBox (nested) pour p1 / p2
if command -v VBoxManage >/dev/null 2>&1; then
  ok "VirtualBox déjà présent"
else
  log "Installation de VirtualBox"
  curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc \
    | gpg --dearmor -o /etc/apt/keyrings/oracle-vbox.gpg
  echo "deb [signed-by=/etc/apt/keyrings/oracle-vbox.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" \
    > /etc/apt/sources.list.d/virtualbox.list
  apt-get update -qq
  apt-get install -y -qq linux-headers-"$(uname -r)" dkms virtualbox-7.0 >/dev/null
  ok "VirtualBox installé"
fi

# VT-x/SVM doit être visible pour le nested (p1/p2)
if grep -qE 'vmx|svm' /proc/cpuinfo; then
  ok "nested virtualization OK (VT-x/SVM visible)"
else
  printf '\033[1;33m[!]\033[0m VT-x/SVM non visible : vérifie --nested-hw-virt (Vagrantfile).\n'
fi

ok "Provisioning terminé."
