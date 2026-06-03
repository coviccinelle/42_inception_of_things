setup:
Fedora (host) → QEMU/KVM → Ubuntu 22.04 VM → Vagrant + VirtualBox → các VM của project
=> this is nested virtualization (VM in VM)


before:
export VAGRANT_HOME=/home/thi-phng/goinfre/.vagrant.d
source ~/.zshrc



Script to verify:
```bash
vagrant up
vagrant ssh thi-phngS #ssh to verify
kubectl get nodes -o wide #you have to see 2 nodes: thi-phngS (control-plane) and thi-phngSW => both are ready
```

out put:
```bash
vit@iot:~/42_inception_of_things/p1$ vagrant ssh thi-phngS
[fog][WARNING] Unrecognized arguments: libvirt_ip_command
Last login: Tue Jun  2 14:16:26 2026 from 192.168.121.1
vagrant@thi-phngS:~$ kubectl get nodes -o wide
NAME         STATUS   ROLES           AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
thi-phngs    Ready    control-plane   10m   v1.35.5+k3s1   192.168.56.110   <none>        Ubuntu 22.04.3 LTS   5.15.0-91-generic   containerd://2.2.3-k3s1
thi-phngsw   Ready    <none>          10m   v1.35.5+k3s1   192.168.56.111   <none>        Ubuntu 22.04.3 LTS   5.15.0-91-generic   containerd://2.2.3-k3s1

```

==================================
