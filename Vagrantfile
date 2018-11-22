# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
# VAGRANTFILE_API_VERSION = "2"
# Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

Vagrant.configure(2) do |config|

  #
  # You can experiment with proxy settings like so:
  #
  # config.proxy.http     = "http://proxy:8083"
  # config.proxy.https    = "http://proxy:8083"
  # config.proxy.no_proxy = "localhost,127.0.0.1"

  #
  # Modify your shared folder here
  #
  config.vm.synced_folder ".", "/var/www/"
  config.vm.synced_folder "install/src", "/var/src/"

  config.vm.box = "bento/ubuntu-18.04"

  config.vm.box_check_update = false

  config.vm.provision :shell, path: "install/bootstrap.sh"
  config.vm.network :forwarded_port, host: 8080, guest: 80
  config.vm.network :forwarded_port, host: 8443, guest: 443
  config.vm.network :private_network, ip: "172.17.0.10"

  config.ssh.username = 'vagrant'
  config.ssh.password = 'vagrant'

  config.vm.provider :virtualbox do |vb|
     vb.name = "csvdb"
     vb.customize ["modifyvm", :id, "--memory", "512"]
     vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end



end
