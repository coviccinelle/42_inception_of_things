# Part 3 — K3d and Argo CD

## Purpose
Demonstrate running a Kubernetes cluster inside Docker using K3d and manage deployments using Argo CD to show a GitOps workflow.

How to install k3d without sudo rights:

```bash
mkdir -p "$HOME/.local/bin" curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | USE_SUDO=false K3D_INSTALL_DIR="$HOME/.local/bin" bash
```

```
GitHub repo (deployment.yaml) ──sync──▶ Argo CD ──deploy──▶ dev namespace
     ↑
  git push (change v1 → v2)
```

### Directory structure
```
p3/
├── scripts/
│   └── setup.sh    # installs Docker, K3d, kubectl, Argo CD
└── confs/
  ├── deployment.yaml    # app manifest (tracked by Argo CD via GitHub)
  └── argocd-app.yaml    # tells Argo CD where to sync from
```

### setup.sh — step by step
```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # add user to docker group
newgrp docker                   # apply group without logout

# 2. Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# 3. Install K3d (K3s inside Docker containers)
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# 4. Create K3d cluster with port forwarding (optional)
# Note: `scripts/setup.sh` creates a cluster named `iot` by default.
k3d cluster create iot \
  --port "8888:30888@loadbalancer"
# host:8888 → loadbalancer → NodePort:30888 → container:8888

# 5. Create namespaces
kubectl create namespace argocd   # for Argo CD components
kubectl create namespace dev      # for the deployed app

# 6. Install Argo CD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 7. Wait for Argo CD to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=300s

# 8. Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### deployment.yaml — app manifest (lives in GitHub)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wil-playground
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wil-playground
  template:
    metadata:
      labels:
        app: wil-playground
    spec:
      containers:
        - name: wil-playground
          image: wil42/playground:v1   # ← change to v2 to trigger update
          ports:
            - containerPort: 8888
---
apiVersion: v1
kind: Service
metadata:
  name: wil-playground
  namespace: dev
spec:
  type: NodePort
  selector:
    app: wil-playground
  ports:
    - port: 8888
      targetPort: 8888
      nodePort: 30888    # must match K3d port forwarding (30888 → 8888)
```

### argocd-app.yaml — Argo CD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wil-playground
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/coviccinelle/42_inception_of_things
    targetRevision: HEAD      # always track latest commit
    path: p3/confs            # folder containing deployment.yaml
  destination:
    server: https://kubernetes.default.svc   # current cluster
    namespace: dev
  syncPolicy:
    automated:
      prune: true       # delete resources removed from Git
      selfHeal: true    # revert manual cluster changes to match Git
    syncOptions:
      - CreateNamespace=true
```

```bash
kubectl apply -f ~/ iot/p3/confs/argocd-app.yaml   # register app with Argo CD
```

### Verify & test
```bash
kubectl get ns                        # check argocd + dev exist
kubectl get pods -n argocd            # all 7 pods Running
kubectl get pods -n dev               # wil-playground Running
curl http://localhost:8888/           # {"status":"ok", "message": "v1"}

kubectl -n argocd get app wil-playground   # STATUS=Synced, HEALTH=Healthy
```

### Update v1 → v2 (the CI/CD demo)
```bash
# 1. Change image tag in deployment.yaml
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/' p3/confs/deployment.yaml

# 2. Push to GitHub → Argo CD detects change and redeploys
git add p3/confs/deployment.yaml
git commit -m "update: playground v1 -> v2"
git push origin main

# 3. Wait ~3 minutes for Argo CD auto-sync, then verify
curl http://localhost:8888/           # {"status":"ok", "message": "v2"}
```

---

## K3s vs K3d — Key Difference

| | K3s | K3d |
|---|---|---|
| **What it is** | Lightweight Kubernetes distro | K3s running inside Docker containers |
| **Used in** | Part 1 & 2 (real VMs via Vagrant) | Part 3 (no Vagrant needed) |
| **How to create nodes** | Vagrant provisions separate VMs | `k3d cluster create` spins up containers |
| **Port forwarding** | VM network (192.168.56.x) | `--port` flag maps host → container |
| **Best for** | Production-like multi-node setup | Fast local dev, CI pipelines |

---

## Useful kubectl cheatsheet

```bash
kubectl get nodes -o wide              # list nodes with IPs
kubectl get pods -n <namespace>        # list pods in namespace
kubectl get all -n <namespace>         # pods + services + deployments
kubectl get ingress                    # list ingress rules
kubectl describe pod <name>            # debug a pod
kubectl logs <pod-name> -n <ns>        # view pod logs
kubectl delete pod <name> -n <ns>      # force pod restart
kubectl -n argocd get app              # list Argo CD applications
```
