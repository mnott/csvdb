#!/bin/bash

#
# Bash RC
#
sudo cp ../.bashrc /root
sudo cp ../.bashrc /home/vagrant
sudo chown vagrant.vagrant /home/vagrant/.bashrc

sudo cp ../bash.bashrc /etc

