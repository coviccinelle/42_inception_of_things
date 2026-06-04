#!/usr/bin/env bash
#
# Setup k3d sur une machine 42 (Fedora) en rootless, sans droits sudo.
#
# Sur ces machines, `docker` est en réalité Podman rootless. k3d a besoin :
#   - du socket Podman utilisateur (podman.socket)
#   - de DOCKER_HOST  -> pour que le client k3d parle à Podman
#   - de DOCKER_SOCK  -> chemin du socket monté DANS les conteneurs k3d
# Sans DOCKER_SOCK, k3d tente de monter /var/run/docker.sock (root) et échoue
# avec "statfs /var/run/docker.sock: permission denied".
#
# Idempotent : peut être relancé sans risque.

set -euo pipefail

K3D_VERSION="${K3D_VERSION:-v5.9.0}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CLUSTER_NAME="${CLUSTER_NAME:-iot}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }

XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PODMAN_SOCK="$XDG_RUNTIME_DIR/podman/podman.sock"

# ---------------------------------------------------------------------------
# 1. Dossier d'installation + PATH
# ---------------------------------------------------------------------------
log "Préparation de $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ok "$INSTALL_DIR déjà dans le PATH" ;;
  *) export PATH="$INSTALL_DIR:$PATH" ; warn "$INSTALL_DIR ajouté au PATH (session courante)" ;;
esac

# ---------------------------------------------------------------------------
# 2. Vérifier la présence d'un moteur de conteneurs (Podman / Docker)
# ---------------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
  warn "Ni docker ni podman trouvés. Installe Podman (rootless) puis relance."
  exit 1
fi
ok "Moteur de conteneurs présent : $(command -v podman || command -v docker)"

# ---------------------------------------------------------------------------
# 3. Installer kubectl (sans sudo) si absent
# ---------------------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  ok "kubectl déjà installé ($(command -v kubectl))"
else
  log "Installation de kubectl dans $INSTALL_DIR"
  KVER="$(curl -sL https://dl.k8s.io/release/stable.txt)"
  curl -sL "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl" -o "$INSTALL_DIR/kubectl"
  chmod +x "$INSTALL_DIR/kubectl"
  ok "kubectl $KVER installé"
fi

# ---------------------------------------------------------------------------
# 4. Installer k3d (sans sudo) si absent ou mauvaise version
# ---------------------------------------------------------------------------
if command -v k3d >/dev/null 2>&1; then
  ok "k3d déjà installé ($(k3d version | head -1))"
else
  log "Installation de k3d $K3D_VERSION dans $INSTALL_DIR"
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
    | USE_SUDO=false K3D_INSTALL_DIR="$INSTALL_DIR" TAG="$K3D_VERSION" bash
  ok "k3d installé"
fi

# ---------------------------------------------------------------------------
# 5. Activer le socket Podman utilisateur
# ---------------------------------------------------------------------------
log "Activation du socket Podman utilisateur"
systemctl --user enable --now podman.socket
# petite attente que le socket apparaisse
for _ in 1 2 3 4 5; do
  [ -S "$PODMAN_SOCK" ] && break
  sleep 1
done
if [ -S "$PODMAN_SOCK" ]; then
  ok "Socket Podman prêt : $PODMAN_SOCK"
else
  warn "Socket Podman introuvable à $PODMAN_SOCK (k3d risque d'échouer)"
fi

# ---------------------------------------------------------------------------
# 5bis. Préflight cgroup v2 : k3s exige le contrôleur 'cpuset'
# ---------------------------------------------------------------------------
# Sans 'cpuset' délégué, k3s meurt au démarrage ("failed to find cpuset cgroup
# (v2)"), le kubeconfig n'est jamais écrit et `k3d cluster create` se bloque.
# La délégation cpuset nécessite root (drop-in /etc/systemd/.../delegate.conf ou
# /sys/fs/cgroup/cgroup.subtree_control) : impossible sans sudo.
USER_CTRL_FILE="/sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers"
if [ -r "$USER_CTRL_FILE" ] && ! grep -qw cpuset "$USER_CTRL_FILE"; then
  warn "Contrôleur cgroup v2 'cpuset' NON délégué à ton utilisateur."
  warn "Disponibles : $(cat "$USER_CTRL_FILE")"
  warn "k3s/k3d ne peuvent PAS démarrer rootless sur cette machine."
  warn "Cause : 'cpuset' absent de /sys/fs/cgroup/cgroup.subtree_control (réservé root)."
  warn "Solutions :"
  warn "  - faire ajouter par le staff 42 un drop-in :"
  warn "      /etc/systemd/system/user@.service.d/delegate.conf"
  warn "      [Service]"
  warn "      Delegate=cpu cpuset io memory pids"
  warn "  - OU lancer k3d DANS une VM (Vagrant/QEMU) où tu es root (voir p3/Vagrantfile)."
  exit 1
fi
ok "Contrôleur cgroup 'cpuset' délégué : OK"

# ---------------------------------------------------------------------------
# 6. Variables d'environnement (session courante)
# ---------------------------------------------------------------------------
export DOCKER_HOST="unix://$PODMAN_SOCK"
export DOCKER_SOCK="$PODMAN_SOCK"
ok "DOCKER_HOST=$DOCKER_HOST"
ok "DOCKER_SOCK=$DOCKER_SOCK"

# ---------------------------------------------------------------------------
# 7. Persister la configuration dans le rc du shell
# ---------------------------------------------------------------------------
RC_FILE="$HOME/.bashrc"
[ -n "${ZSH_VERSION:-}" ] && RC_FILE="$HOME/.zshrc"
case "${SHELL:-}" in */zsh) RC_FILE="$HOME/.zshrc" ;; esac

MARKER="# >>> k3d rootless podman (iot p3) >>>"
if grep -qF "$MARKER" "$RC_FILE" 2>/dev/null; then
  ok "Configuration déjà présente dans $RC_FILE"
else
  log "Ajout de la configuration dans $RC_FILE"
  {
    echo ""
    echo "$MARKER"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo 'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"'
    echo 'export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"'
    echo 'export DOCKER_SOCK="$XDG_RUNTIME_DIR/podman/podman.sock"'
    echo "# <<< k3d rootless podman (iot p3) <<<"
  } >> "$RC_FILE"
  ok "Configuration ajoutée (relance ton shell ou: source $RC_FILE)"
fi

# ---------------------------------------------------------------------------
# 8. Créer le cluster k3d si absent
# ---------------------------------------------------------------------------
if k3d cluster list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$CLUSTER_NAME"; then
  ok "Cluster k3d '$CLUSTER_NAME' déjà présent"
else
  log "Création du cluster k3d '$CLUSTER_NAME'"
  k3d cluster create "$CLUSTER_NAME"
  ok "Cluster '$CLUSTER_NAME' créé"
fi

# ---------------------------------------------------------------------------
# 9. Vérification finale
# ---------------------------------------------------------------------------
log "Vérification du cluster"
kubectl cluster-info
kubectl get nodes

echo
ok "Setup terminé. Le cluster '$CLUSTER_NAME' est prêt."
