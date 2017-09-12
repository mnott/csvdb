#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

sudo apt-get update
sudo apt-get -y upgrade

echo "Custom installations..."

cd /var/src/configure

./configure.sh

echo "Done."
