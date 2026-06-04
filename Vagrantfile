# Inception of Things — VM de dev "tout-en-un".
#
# Pourquoi : sur la machine 42, `docker` est Podman rootless et le contrôleur
# cgroup v2 `cpuset` n'est PAS délégué (réservé root) -> k3s/k3d ne peuvent pas
# tourner en rootless sur l'hôte. On crée donc une VM où l'on est root, avec la
# virtualisation imbriquée (nested) activée, pour lancer p1, p2 et p3 depuis la VM :
#   - p1 / p2 : projets Vagrant -> tournent en nested (Vagrant + VirtualBox dans la VM)
#   - p3      : k3d -> tourne nativement (Docker dans la VM)
#
# Démarrage :
#   vagrant up
#
# Puis :
#   vagrant ssh
#   cd ~/iot/p3 && ./scripts/setup.sh                # cluster k3d
#   cd ~/iot/{p1,p2} && vagrant up                   # nested (VirtualBox)
#
# Ressources configurables via variables d'env :
#   IOT_CPUS=4 IOT_MEMORY=6144 vagrant up

CPUS   = (ENV["IOT_CPUS"]   || "4").to_i
MEMORY = (ENV["IOT_MEMORY"] || "6144").to_i   # Mo

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_check_update = false
  config.vm.hostname = "iot-dev"

  # Tout le projet est partagé dans la VM (édition côté hôte, exécution côté VM).
  config.vm.synced_folder ".", "/home/vagrant/iot"

  # Stocker les VMs VirtualBox dans ~/goinfre (quota disque 42).
  config.trigger.before :up do |trigger|
    trigger.run = {
      inline: "bash -c 'mkdir -p ~/goinfre/\"VirtualBox VMs\" && VBoxManage setproperty machinefolder ~/goinfre/\"VirtualBox VMs\"'"
    }
  end

  config.vm.provider "virtualbox" do |vb|
    vb.cpus   = CPUS
    vb.memory = MEMORY
    # Nested hardware virt : indispensable pour lancer p1/p2 (VirtualBox) DANS la VM.
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
  end

  config.vm.provision "shell", path: "scripts/provision.sh"
end
