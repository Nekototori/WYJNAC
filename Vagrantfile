Vagrant.configure("2") do |config|
  # Base Ubuntu 22.04 box
  config.vm.box = "ubuntu/jammy64"
  #config.puppet_install.puppet_version = "8.10" This plugin doesn't work now. Neat.
  #config.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y puppet-agent"  This doesn't work either now, yay. 

  # Control plane
  config.vm.define "k8s-controlplane" do |controlplane|
    controlplane.vm.hostname = "k8s-controlplane"
    controlplane.vm.network "private_network", ip: "192.168.69.10"
    controlplane.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 4
    end
    controlplane.vm.provision "shell", inline: "wget https://apt.puppetlabs.com/puppet8-release-jammy.deb"
    
    controlplane.vm.provision "shell", inline: "sudo dpkg -i puppet8-release-jammy.deb"
    controlplane.vm.provision "shell", path: "vagrant_scripts/container_setup.sh"
    controlplane.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y puppet-agent"
    
    #If a fresh provision of the control plane, we clean up this file here just to not make Puppet even more jank.
    controlplane.vm.provision "shell", inline: "rm -f /vagrant/join_command.sh"
    
    # Yay Puppet. I know what that is!

    controlplane.vm.provision "puppet" do |puppet|
      puppet.manifest_file = "k8s_allnodes.pp"
    end

    controlplane.vm.provision "puppet" do |puppet|
      puppet.manifest_file = "k8s_controlplane.pp"
    end
  end

  # Worker nodes
  (1..2).each do |i| # Can add more here for scale. yay.
    config.vm.define "k8s-worker#{i}" do |worker|
      worker.vm.hostname = "k8s-worker#{i}"
      worker.vm.network "private_network", ip: "192.168.69.1#{i+0}"
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus = 4
      end
 
    worker.vm.provision "shell", inline: "wget https://apt.puppetlabs.com/puppet8-release-jammy.deb"
    
    worker.vm.provision "shell", inline: "sudo dpkg -i puppet8-release-jammy.deb"
    worker.vm.provision "shell", path: "vagrant_scripts/container_setup.sh"
    worker.vm.provision "shell", path: "vagrant_scripts/user_certgen.sh"
    worker.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y puppet-agent"
    
    #worker.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y puppet-agent"   

      worker.vm.provision "puppet" do |puppet|
        puppet.manifest_file = "k8s_allnodes.pp"
      end

      worker.vm.provision "puppet" do |puppet|
        puppet.manifest_file = "k8s_worker.pp"
      end
    end
  end
end
