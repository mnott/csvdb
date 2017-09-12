#!/bin/bash

#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password dg'
#sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password dg'

sudo apt-get install -y apache2
#sudo apt-get install -y php mysql-server php-mysql php-curl php-imagick

sudo service apache2 reload

sudo chown vagrant:vagrant /etc/apache2/sites-available
sudo chown vagrant:vagrant /etc/apache2/sites-enabled

sudo a2enmod ssl
sudo a2enmod rewrite

if [ -f /etc/apache2/sites-available/default-ssl.conf ]; then
  sudo rm /etc/apache2/sites-available/default-ssl.conf
fi

sudo service apache2 restart

