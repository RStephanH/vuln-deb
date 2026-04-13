# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # ─── Base Box ───────────────────────────────────────────────────────────────
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "vuln-telnet-lab"

  # ─── Network ────────────────────────────────────────────────────────────────
  # Host-only network: only YOUR machine can reach the VM (safe!)
  config.vm.network "private_network", ip: "192.168.56.10"

  # ─── VirtualBox Provider ────────────────────────────────────────────────────
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "vuln-telnet-lab"
    vb.memory = "512"
    vb.cpus   = 1
    vb.gui    = false
  end

  # ─── Provisioning ───────────────────────────────────────────────────────────
  config.vm.provision "shell", path: "provision/setup.sh"

end
