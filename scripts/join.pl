#!/bin/sh
exec perl -x $0 "$@"
#!/usr/bin/env perl -I lib
###################################################
#
# Join two CSV files, uniqueing by first column
#
# (c) 2017 Matthias Nott
#
###################################################

use 5.22.1;
use strict;
use warnings;

binmode STDOUT, ":utf8";
use utf8;


use File::Basename qw(dirname);
use Cwd qw(abs_path);

use Data::Dump "pp";

use Text::CSV;

use CSVdb::TConfig;
use CSVdb;

$ENV{ROOT} = dirname( abs_path $0) . "/../";

#
# Initialize the Logger
#
Log::Log4perl->init_once( $ENV{ROOT} . '/log4p.ini' );

my $log = Log::Log4perl::get_logger("CSVdb");

if ( exists $ENV{LOGLEVEL} && "" ne $ENV{LOGLEVEL} ) {
    $log->level( uc $ENV{LOGLEVEL} );
}


#
# Instantiate the Configuration holder
#
my $cfg = CSVdb::TConfig->new;


#
# Instantiate the CSV handler
#
my $csvdb = CSVdb->new( cfg => $cfg );


#
# Get the command line options:
#
# input csv1
# input csv2
#
if ( @ARGV < 1 ) {
    print STDERR "$0\n";

    print STDERR <<'USAGE';

    Remove duplicates from a CSV file, based on the
    first column, which needs to be a combination of
    what makes a given row unique.

    That first column will be removed from the output.

    The environment variable DATASET needs to point to
    a directory where the table to be joined lives as
    a csv file.

    For example:
USAGE

    print STDERR "\n    $0 input\n\n";
    exit 1;
}

my $dataset = $ENV{'DATASET'};
my $sql     = "select * from $ARGV[0]";

#my $sql     = "select * from temp order by keychen";

$cfg->set( "raw", 1 );
$cfg->set( "debug", 1 );
$cfg->set( "sql", $sql );
$cfg->set( "dir", "$dataset" );

$csvdb->run();
my @results = split "\n", $csvdb->result();

my $csv = Text::CSV->new();

my $lines = 0;
my %unique_results;


#
# Select all rows, shifting out the first column to the left,
# and adding them to a hash which will automatically unique
# the results
#
foreach my $row (@results) {
    $csv->parse($row);
    my @fields = $csv->fields();

    if ( !$lines ) {
        shift @fields;
        my $hcsv = Text::CSV->new ({always_quote => 0});
        $hcsv->combine(@fields);
        print $hcsv->string . "\n";
    }
    else {
        my $key = $fields[0];
        shift @fields;
        $unique_results{$key} = \@fields;
    }

    $lines++;

}

#
# Retrieve the results from the hash, and print
# them as a CSV
#
my $duplicates = 1;

foreach my $key ( keys(%unique_results) ) {
    my @fields = @{ $unique_results{$key} };
    $csv = Text::CSV->new( { always_quote => 0 } );
    $csv->combine(@fields);

    print $csv->string . "\n";

    $duplicates++;
}

$duplicates = $lines - $duplicates;

print STDERR "\nRemoved $duplicates duplicates.\n";
