# 42_inception_of_things
 
## Project summary
This project is a hands-on exercise for deploying and operating lightweight Kubernetes clusters (K3s / K3d), integrating Argo CD for GitOps-style application delivery, and using Vagrant-based virtual machines for environment isolation. It is intended to teach how to configure, deploy, and manage cloud-native applications across different local environments.

Main goals:
- Set up lightweight Kubernetes clusters using K3s (via Vagrant VMs) and K3d (in Docker).
- Deploy three simple sample applications and verify ingress routing.
- Configure Argo CD to manage application deployments following GitOps principles.

## Basic explanation (main parts)
- Part 1: K3s and Vagrant — Vagrantfiles and VM configuration to provision VMs that run K3s.
- Part 2: K3s and three simple applications — Kubernetes manifests, ingress configuration, and resources to deploy three sample apps.
- Part 3: K3d and Argo CD — use K3d to run clusters in Docker and demonstrate Argo CD for automated deployments.

## Dictionary
- Ingress: an API object that manages external access to the services in a cluster, typically HTTP.
- Vagrant: is the command-line utility for managing the lifecycle of virtual machines. Isolate dependencies and their configuration within a single disposable and consistent environment -> like VirtualBox, but without a graphical interface.

## Part 1: K3s and Vagrant


## Part 2: K3s and three simple applications
<img width="466" height="513" alt="image" src="https://github.com/user-attachments/assets/76dddce9-7c46-4db3-ab89-332b3fbfcfb4" />


##  Part 3: K3d and Argo CD
<img width="345" height="270" alt="image" src="https://github.com/user-attachments/assets/77dfe632-0f37-4e5f-ba69-6999c21210b2" />


if Vagrant virtualbox error in cluster 42
```bash
find ~ -name "VirtualBox.xml" 2>/dev/null
rm -rf ~/.config/VirtualBox
echo 'export VAGRANT_HOME=~/goinfre/.vagrant.d' >> ~/.zshrc
source ~/.zshrc
rm -rf .vagrant
vagrant up
```
