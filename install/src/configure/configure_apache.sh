#!/bin/bash

#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password dg'
#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password dg'

sudo apt-get install -y apache2
#sudo apt-get install -y php mysql-server php-mysql php-curl php-imagick

if [ -f ../mod_perl.conf ]; then
  sudo cp ../mod_perl.conf /etc/apache2/conf-available
fi

sudo apt-get install -y libapache2-mod-perl2
#sudo apt-get install -y libapache2-mod-apreq2 #-???
sudo apt-get install -y libapache2-request-perl

sudo service apache2 reload

sudo chown vagrant:vagrant /etc/apache2/sites-available
sudo chown vagrant:vagrant /etc/apache2/sites-enabled

sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enconf mod_perl

if [ -f /etc/apache2/sites-available/default-ssl.conf ]; then
  sudo rm /etc/apache2/sites-available/default-ssl.conf
fi

#
# Seriously low. We aren't using a real database, and
# CSVdb consumes a lot of memory per request  (about
# 30 MB in our scenario reading about a 10 MB file).
#
echo MaxConnectionsPerChild 3 >>/etc/apache2/apache2.conf

sudo service apache2 restart

