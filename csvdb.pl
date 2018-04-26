#!/bin/sh
exec perl -x $0 "$@"
#!/usr/bin/env perl -I lib
###################################################
#
# Treat a csv like a database
#
# (c) 2017 Matthias Nott
#
###################################################

=head1 NAME

csvdb - Database Operations for CSV Files

=head1 VERSION

Version 0.0.2

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017 Matthias Nott (mnott (at) mnsoft.org).

Licensed under WTFPL.

=cut

###################################################
#
# Dependencies
#
###################################################

use 5.22.1;
use strict;
use warnings;

binmode STDOUT, ":utf8";
use utf8;
use Getopt::Long;
use Config::Simple;
use Pod::Usage;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Data::Dump "pp";

###################################################
#
# Relative Library Directory Lookup
#
###################################################

use lib dirname( Cwd::abs_path $0) . '/lib';

use CSVdb::TConfig;
use CSVdb;


$ENV{ROOT} = dirname( abs_path $0);

###################################################
#
# About the documentation:
#
# Created like
#
# pod2markdown.pl <texdown.pl >README.md
#
# Using the excellent podmarkdown by Randy Stauner.
#
###################################################

my $pod2md = "pod2markdown.pl";    # Must be in $PATH


#
# Instantiate the Configuration holder
#
my $cfg = CSVdb::TConfig->new;


#
# Instantiate the CSV handler
#
my $csvdb = CSVdb->new( cfg => $cfg );


#
# Get the command line options
#
GetOptions(
    'n|no|nothing'      => sub { $cfg->append(@_); },
    'debug|d'           => sub { $cfg->append(@_); },
    'dir:s'             => sub { $cfg->append(@_); },
    'cols|c:s'          => sub { $cfg->append(@_); },
    'kols|k:s'          => sub { $cfg->append(@_); },
    'hdr|h:s'           => sub { $cfg->append(@_); },
    'raw|r'             => sub { $cfg->append(@_); },
    'sql|s:s'           => sub { $cfg->append(@_); },
    'quote|q'           => sub { $cfg->append(@_); },
    'view|v:s'          => sub { $cfg->append(@_); },
    'params|p:s{,}'     => sub { $cfg->append(@_); },
    'doc|documentation' => sub { $cfg->append(@_); },
    'help'              => sub { $cfg->append(@_); },
    'man'               => sub { $cfg->append(@_); },
) or pod2usage(2);
pod2usage(1) if $cfg->contains_key("h");

pod2usage( -exitval => 0, -verbose => 2 ) if $cfg->contains_key("man");

#
# Shortcut for myself to recreate the documentation
# without having to remember how it was done.
#
if ( $cfg->get("doc") ) {
    system("$pod2md < $0 >README.md");
    exit 0;
}


#
# Run
#
$csvdb->run();
print $csvdb->result();


#
# Done
#
#$log->trace("Done.");


###################################################
#
# Documentation
#
###################################################

__END__

=head1 INTRODUCTION

            The program was written to provide for database
            operations on csv files. You can run use it to
            analyze csv files as if they were database tables.

=head1 SYNOPSIS

./csvdb.pl [options]

csvdb interprets all .csv files in the current directory as tables.

You can of course have the whole git repository somewhere else and
have its csvdb.pl on the path.

You can specify a data directory on the command line like so:

  ./csvdb.pl -d data/xyz/data/ -s "select id, name from employee"

This tells the program to look for employee.csv within the directory
data/xyz/data.

Alternatively, you can also specify the xyz directory using an
environment variable DATASET, which will make the data directory
to default to, if DATASET is xyz, data/xyz/data:

  export DATASET=xyz
  ./csvdb.pl -s "select id, name from employee"

Or, you can do it all in one line:

  DATASET=xyz ./csvdb.pl -s "select id, name from employee"

So if, for example, you do only this:

  ./csvdb.pl -s "select distinct id, name from employee order by name"

Then this expects to find a file employee.csv (in the current directory,
because a dataset directory was not defined), with at least a header
line containing something like id, name, which are going to be the
column headers.

      Notice that column headers are going to be simplified in the sense
      that all special characters, including spaces, are replaced by
      underscores. If in doubt, use the "-c" option to get a list of
      column headers for your query.

Command line parameters can take any order on the command line.

 Options:

   General Options:

   -help            brief help message (alternatives: ?, -h)
   -man             full documentation (alternatives: -m)
   -d               debug (alternatives: -debug): Print out sql statements.

   csvdb Options:

   -dir data        The location of the csv files. Default: ./data/

   -c somefile      Show the csv columns in somefile.csv in alphabetical order
   -k somefile      Show the csv columns in somefile.csv in their original order

   -s "select..."   Execute a select statement

   -v somefile.sql  Execute a select statement in some file

   -p               Interpret the following as key=value pair for a query

   -r               Output the result of the query in csv format
   -h               When using -r, do not output the column headers
   -q               When using -q, quote all columns (also numbers)

   Other Options:

   -documentation   Recreate the README.md (needs pod2markdown)


=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-documentation>

Regenerate the README.md file

=item B<-dir>

Specify the directory within which the data files (.csv files)
are to be located. Default is a directory "data" under the current
directory.

=item B<-d>

Print the generated sql statement to stderr. This can be useful
if you receive errors from the database engine, in order to
understand what was actually tried to select.

=item B<-c>

Show the columns in a given file, in alphabetical order.

For example:

  ./csvdb.pl -c employee
  id
  name

This assumes that there is a file employee.csv in the data
directory.


=item B<-k>

Show the columns in a given file, in their original order.

For example:

  ./csvdb.pl -k employee
  name
  id

This assumes that there is a file employee.csv in the data
directory.

=item B<-s>

Run a query from the command line. For example:

  ./csvdb.pl -s "select distinct id, name from employee order by name"
  2, Hinz
  1, Kunz

This assumes that there is a file employee.csv in the data
directory.

=item B<-v>

Run a query from a file. For example:

  ./CSVdb.pl -v employees.sql

This assumes there is an employees.sql (you can give a path to
that file) which contains the actual query. This file is called
a view.

Lines starting with a # are ignored, and all other lines are
concatenated into one single line. If you are unsure about
the resulting query, use the -d command line option.

For example:

  #
  # Select for EMPLOYEE
  #
  # Parameters:
  #
  # none
  #
  select
    e.id                      as EmpId,
    e.name                    as EmpName
  from employee e
  order by
    e.name

=item B<-p>

Any query, be it on the command line (where it doesn't make too
much sense) or from a view file, can contain parameters. These
can be specified on the command line, and if they exist, they
are going to be replaced into the query. Here is a more complex
query which uses CUSTOMER that it replaces into the query, and
also an optional _WHERE_ placeholder which, if not specified on
the command line, will be removed. Also, the following example
shows how to join multiple tables (in the given example, we want
to see from some pipeline.csv file only the products which we find
in a products.csv file):

  ./csvdb.pl -v customer.sql -p CUSTOMER="New York Times" -p _WHERE_="and p.acv_keur > 100"

Here is a more complex view:

  #
  # Select for CUSTOMER
  #
  # Parameters:
  #
  # CUSTOMER
  # _WHERE_ (optional)
  #
  select
    p.country                 as Country,
    p.bp_org_name             as Customer,
    p.opportunity_owner_name  as Opp_Owner,
    p.opportunity_id          as Opp_Id,
    p.closing_date            as Close_Date,
    p.opp_phase               as Phase,
    p.fc_qualification        as Category,
    p.opportunity_description as Opp_Desc,
    p.product                 as Product,
    p.product_desc            as Product_Desc,
    p.acv_keur                as ACV,
    p.tcv_keur                as TCV
  from pipeline p
  join hcp on p.product = hcp.product
  where
        p.revenue_type   = 'New Software'
    and p.opp_status     = 'In process'
    and p.bp_org_name    like '%CUSTOMER%'
    _WHERE_
  order by
    bp_org_name,
    tcv_keur desc


=item B<-r>

Output the result of a query not in tabular, but in csv format.
This is useful if you want to run further queries on the result
of a given query. Notice that the column headers are going to be
potentially different from the original table; special characters
can be escaped using underscores, and also, you may have used the
"AS" statement in the query.


=item B<-h>

When using -r, do not output the column headers. This can be
useful if you want to collect the results of multiple queries
into one target file, appending as you go along.


=item B<-q>

When using -r, quote all columns in the output - this may or
may not be useful, as numbers are going to be quoted too with
this option; when importing the resulting file into, for example,
Excel, Excel will interpret them as text.


=back


=head1 INSTALLATION

The program uses a number of perl modules. You can install
those modules, if you are on a Linux or MacOS system, using
the script B<install/src/configure/configure_perl.sh>. This
will attempt to install the modules for you.

Here is a walkthrough of the installation under Ubuntu:

  root[14:48:58]@ltest:~# export LANG=C
  root[14:49:03]@ltest:~# apt-get install -y git
  Reading package lists... Done
  Building dependency tree
  Reading state information... Done
  git is already the newest version (1:2.7.4-0ubuntu1.3).
  0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
  root[14:49:09]@ltest:~# cd /usr/local/bin
  root[14:49:20]@ltest:/usr/local/bin# git clone https://github.com/mnott/csvdb csvdb-bin
  Cloning into 'csvdb-bin'...
  remote: Counting objects: 440, done.
  remote: Compressing objects: 100% (60/60), done.
  remote: Total 440 (delta 45), reused 79 (delta 36), pack-reused 344
  Receiving objects: 100% (440/440), 133.57 KiB | 0 bytes/s, done.
  Resolving deltas: 100% (228/228), done.
  Checking connectivity... done.
  root[14:49:33]@ltest:/usr/local/bin#
  root[14:49:33]@ltest:/usr/local/bin# ln -s csvdb-bin/csvdb.pl csvdb
  root[14:49:33]@ltest:/usr/local/bin# cd csvdb/install/src/configure
  root[14:52:06]@ltest:/usr/local/bin/csvdb/install/src/configure# ./configure_perl.sh
  root[15:12:45]@ltest:/usr/local/bin/csvdb/install/src/configure# cd /tmp
  root[15:12:47]@ltest:/tmp# echo "a,b" >test.csv
  root[15:12:57]@ltest:/tmp# echo 1,2>>test.csv
  root[15:13:02]@ltest:/tmp# echo 3,4>>test.csv
  root[15:13:06]@ltest:/tmp# csvdb -s "select a, b from test where a=3"
  a b
  3 4


Alternatively, if you do not want to mess with your local
installation, you can install the whole package as to run
inside a virtual machine (only install what you have not
yet got):

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://www.vagrantup.com/downloads.html)
3. Install [Git](https://git-scm.com/download)
4. Install [Vagrant Manager](https://github.com/deveres/vagrant-manager-windows/releases/download/1.0.0.7/vagrant-manager-windows-1.0.0.7.exe)

If you don't want to deal with Vagrant via the command line, there
is an excellent frontend about it. The link above for
Vagrant Manager is a special version for Windows
that has resolved an issue where Vagrant Manager would get stuck on
refreshing the list of virtual machines. If you run on Mac or others,
you can download the default version: [Vagrant Manager](http://vagrantmanager.com)
It is highly recommendable to use Vagrant Manager.


When you download VirtualBox, don't forget to also download the
extension pack (on the same page).

Very important: If you are working on a Windows system, make sure
to configure Git, when it installs, to *not automatically* convert
Line Ends ("CR/LF"). Shouly you have configured it wrongly, you can
do this on the command line:

  git config --global core.autocrlf false

Also, before continuing, make sure that you have switched on
Virtualization in your BIOS (the feature is often under either
Configuration or Security, and is often called Intel Virtualization
Technology and VT-d Feature: Enable both). If you fail to do this,
the virtual machine will not start up, and also may be recognized
wrongly as 32bit.

Finally, you open a command line, e.g. on your Desktop, and do this:


  git clone https://github.com/mnott/csvdb
  cd csvdb
  vagrant up



You should then be able to open
[the web application](http://localhost:8080/).

To SSH into your virtual machine, you can just use

  vagrant ssh

and then, to become root,

  sudo su -

You can stop the virtual machine using, from the csvdb directory,

  vagrant suspend

You can delete the virtual machine using, from the csvdb directory,

  vagrant destroy


=cut

