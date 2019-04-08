# -*- mode: ruby -*-
# vi: set ft=ruby :
# See: https://docs.vagrantup.com/v2/vagrantfile/tips.html


VAGRANTFILE_API_VERSION = "2"

VIRTUAL_MACHINES = {
  :kube01 => {
    :ip             => '10.0.15.21',
    :port           => 8081,
  },
  :kube02 => {
    :ip             => '10.0.15.22',
    :port           => 8082,
  },
  :master => {
    :ip             => '10.0.15.10',
    :port           => 8080,
  }
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.hostmanager.enabled = true
  config.vm.box = "centos/7"
  config.ssh.insert_key = false
#  config.vm.synced_folder '.', '/vagrant', disabled: true
  VIRTUAL_MACHINES.each do |name,cfg|

    config.vm.define name do |vm_config|
      vm_config.vm.hostname = name
      vm_config.vm.network :private_network, ip: VIRTUAL_MACHINES[name][:ip]
      config.vm.network "forwarded_port", guest: 31227, host: VIRTUAL_MACHINES[name][:port]
      config.vm.provider :virtualbox do |vb|

        vb.memory = 3072
        vb.cpus = 2
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]

      end # provider

    config.vm.provision "shell",
        inline: ":"
    end

  end
end
