#!/bin/bash

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

# Install a whole bunch of Perl packages
sudo curl -L https://cpanmin.us 2>/dev/null | perl - App::cpanminus
sudo cpanm Data::Dump
sudo cpanm Text::Table
sudo cpanm Text::CSV
sudo cpanm Tie::IxHash
sudo cpanm DBI
sudo cpanm File::BOM
sudo cpanm DBD::CSV
sudo cpanm Pod::Markdown
sudo cpanm Config::Simple
sudo cpanm Moose
sudo cpanm Log::Log4perl
sudo cpanm namespace::autoclean
sudo cpanm XML::LibXML
sudo cpanm XML::LibXML::PrettyPrint
sudo cpanm MooseX::Log::Log4perl
sudo cpanm Log::Dispatch::Screen
sudo cpanm URL::Encode
sudo cpanm Apache::Session::File
sudo cpanm Cache::Memcached
sudo cpanm Digest::MD5
sudo cpanm JSON
sudo cpanm File::Slurp


# Update to the current version of cvsdb to fix BOM error
cd /tmp
git clone https://github.com/perl5-dbi/DBD-CSV.git DBD-CSV
cd DBD-CSV
AUTOMATED_TESTING=1 perl Makefile.PL
make install
cd ..
rm -fr DBD-CSV
