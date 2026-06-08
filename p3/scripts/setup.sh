#!/usr/bin/env bash
# Partie 3 : Docker + kubectl + k3d + cluster. À lancer dans la VM iot-dev.
# Idempotent.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-iot}"
PORT_MAPPING="${PORT_MAPPING:-8888:30888@loadbalancer}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARGOCD_APP_FILE="$DIR/../confs/argocd-app.yaml"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

log "path DIR: $DIR"
log "path ARGOCD_APP_FILE: $ARGOCD_APP_FILE"

# Docker
if command -v docker >/dev/null 2>&1; then
  ok "Docker déjà présent"
else
  log "Installation de Docker"
  curl -fsSL https://get.docker.com | sudo sh
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  ok "Docker installé"
fi

# Activer le groupe docker dans la session (ré-exécution unique)
if ! docker info >/dev/null 2>&1 && [ -z "${IOT_REEXEC:-}" ]; then
  log "Activation du groupe docker"
  exec sg docker -c "IOT_REEXEC=1 bash '$(readlink -f "$0")'"
fi

# kubectl
if command -v kubectl >/dev/null 2>&1; then
  ok "kubectl déjà présent"
else
  log "Installation de kubectl"
  KVER="$(curl -sL https://dl.k8s.io/release/stable.txt)"
  curl -sL "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl" -o /tmp/kubectl
  sudo install /tmp/kubectl /usr/local/bin/kubectl && rm /tmp/kubectl
  ok "kubectl $KVER installé"
fi

# k3d
if command -v k3d >/dev/null 2>&1; then
  ok "k3d déjà présent ($(k3d version | head -1))"
else
  log "Installation de k3d"
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash
  ok "k3d installé"
fi

# Cluster
if k3d cluster get "$CLUSTER_NAME" >/dev/null 2>&1; then
  ok "Cluster '$CLUSTER_NAME' déjà présent"
else
  log "Création du cluster '$CLUSTER_NAME' (port: $PORT_MAPPING)"
  k3d cluster create "$CLUSTER_NAME" --port "$PORT_MAPPING"
  ok "Cluster '$CLUSTER_NAME' créé"
fi

log "Vérification"
kubectl get nodes
ok "Cluster '$CLUSTER_NAME' prêt."

# Namespaces
if kubectl get namespace argocd >/dev/null 2>&1; then
  ok "Namespace 'argocd' déjà présent"
else
  log "Création namespace 'argocd'"
  kubectl create namespace argocd
  ok "Namespace 'argocd' créé"
fi

if kubectl get namespace dev >/dev/null 2>&1; then
  ok "Namespace 'dev' déjà présent"
else
  log "Création namespace 'dev'"
  kubectl create namespace dev
  ok "Namespace 'dev' créé"
fi

# Install Argo CD (idempotent)
if kubectl -n argocd get deployment argocd-server >/dev/null 2>&1; then
  ok "Argo CD déjà installé"
else
  log "Installation de Argo CD"
  kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  ok "Manifests Argo CD appliqués"

  log "Attente Argo CD prêt (server pod)"
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
  ok "Argo CD server prêt"

  log "Argocd admin password:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d || true
fi

# Apply local Argo CD Application manifest if present
if [ -f "$ARGOCD_APP_FILE" ]; then
  log "Apply Argo CD Application: $ARGOCD_APP_FILE"
  kubectl apply -f "$ARGOCD_APP_FILE"
  ok "Argo CD Application applied"
fi
