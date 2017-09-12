# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
# VAGRANTFILE_API_VERSION = "2"
# Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

Vagrant.configure(2) do |config|

  #
  # Modify your shared folder here
  #
  config.vm.synced_folder ".", "/var/www/"
  config.vm.synced_folder "install/src", "/var/src/"

  config.vm.box = "bento/ubuntu-16.04"

  config.vm.provision :shell, path: "install/bootstrap.sh"
  config.vm.network :forwarded_port, host: 8080, guest: 80
  config.vm.network :forwarded_port, host: 8443, guest: 443
  config.vm.network :private_network, ip: "172.17.0.10"

  config.ssh.username = 'vagrant'
  config.ssh.password = 'vagrant'

  config.vm.provider :virtualbox do |vb|
     vb.name = "dg"
     vb.customize ["modifyvm", :id, "--memory", "512"]
     vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      mkdir -p /root/.ssh
      chmod 600 /root/.ssh
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
      echo #{ssh_pub_key} >> /root/.ssh/authorized_keys2
    SHELL
  end

end