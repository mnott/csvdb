#!/bin/bash

sudo apt-get install -y perl-doc

sudo cp ../pod2markdown.pl /usr/local/bin/

sudo curl -L https://cpanmin.us 2>/dev/null | perl - App::cpanminus
sudo cpanm Data::Dump
sudo cpanm Text::Table
sudo cpanm Text::CSV
sudo cpanm Tie::IxHash
sudo cpanm DBI
sudo cpanm File::BOM
sudo cpanm DBD::CSV
sudo cpanm Pod::Markdown
