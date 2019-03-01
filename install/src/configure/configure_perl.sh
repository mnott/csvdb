#!/bin/bash

if [ ! -z ${http_proxy+x} ]; then
  echo HTTP Proxy: $http_proxy
fi

if [ `uname -s` == Linux ]; then
  sudo apt-get install -y perl-doc
  sudo apt-get install -y libxml2-dev
  sudo apt-get install -y zlib1g-dev
  sudo apt-get install -y memcached
  sudo apt-get install -y libcache-memcached-perl
  sudo sed -i 's/^-m 64/-m 128/' /etc/memcached.conf
  sudo echo "-I 16M" >>/etc/memcached.conf
  sudo service memcached restart
  sudo update-rc.d memcached defaults
fi

# Install Pod2markdown
if [ -f ../pod2markdown.pl ]; then
  sudo cp ../pod2markdown.pl /usr/local/bin/
fi

# Install cpanm
sudo curl -L https://cpanmin.us 2>/dev/null | perl - App::cpanminus

# Install Ports Utility
if [ -f ../ports ]; then
  sudo cp ../ports /usr/local/bin
  sudo chmod 755 /usr/local/bin/ports
  sudo cpanm --notest Proc::ProcessTable
fi

# Install a whole bunch of Perl packages
sudo cpanm --notest Data::Dump
sudo cpanm --notest Text::Table
sudo cpanm --notest Text::CSV
sudo cpanm --notest Tie::IxHash
sudo cpanm --notest DBI
sudo cpanm --notest File::BOM
sudo cpanm --notest DBD::CSV
sudo cpanm --notest Pod::Markdown
sudo cpanm --notest Config::Simple
sudo cpanm --notest Moose
sudo cpanm --notest Log::Log4perl
sudo cpanm --notest namespace::autoclean
sudo cpanm --notest XML::LibXML
sudo cpanm --notest XML::LibXML::PrettyPrint
sudo cpanm --notest MooseX::Log::Log4perl
sudo cpanm --notest Log::Dispatch::Screen
sudo cpanm --notest URL::Encode
sudo cpanm --notest Apache::Session::File
sudo cpanm --notest Cache::Memcached
sudo cpanm --notest Digest::MD5
sudo cpanm --notest JSON
sudo cpanm --notest File::Slurp
sudo cpanm --notest DateTime::Format::Strptime

# Update to the current version of cvsdb to fix BOM error
cd /tmp
git clone https://github.com/perl5-dbi/DBD-CSV.git DBD-CSV
cd DBD-CSV
AUTOMATED_TESTING=1 perl Makefile.PL
make install
cd ..
rm -fr DBD-CSV


