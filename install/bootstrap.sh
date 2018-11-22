#!/bin/bash

###############################################################
#
# Configuration Section
#

#
# Uncomment the following two lines if you want to use a proxy
#
#export http_proxy=http://192.168.1.2:8888/

#
# End of Configuration
#
###############################################################


if [ ! -z ${http_proxy+x} ]; then
  echo http_proxy=$http_proxy >>/etc/environment
fi

echo DEBIAN_FRONTEND=noninteractive >>/etc/environment

sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

sudo apt-get update
# sudo apt-get -y upgrade

sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

echo "Custom installations..."

cd /var/src/configure

./configure.sh

echo "Done."
