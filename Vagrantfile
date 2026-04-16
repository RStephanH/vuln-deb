Vagrant.configure("2") do |config|

  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "vuln-telnet-lab"

  # host-only
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "vuln-telnet-lab"
    vb.memory = "512"
    vb.cpus   = 1
    vb.gui    = false
  end

  config.vm.provision "shell", path: "provision/setup.sh"

end
