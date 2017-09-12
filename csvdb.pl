#!/usr/bin/env perl
###################################################
#
# Treat a csv like a database
#
# (c) 2017 Matthias Nott
#
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
use Data::Dump "pp";
use Text::Table;
use Text::CSV;
use Tie::IxHash;
use DBI;
use File::BOM;
use Getopt::Long;
use Pod::Usage;


###################################################
#
# Forward Declarations
#
###################################################

sub dbi_connect;
sub dbi_disconnect;
sub tbl_columns;
sub view_select;
sub tbl_select;
sub parse_sql;


###################################################
#
# Globals
#
###################################################

my $dbh;  # The database connection
my $sth;  # The result set
my @cols; # The columns from the result set


###################################################
#
# Parse the Command Line.
#
###################################################

my %OPTS = (
    debug  => 0,
    dir    => 'data',
    cols   => '',
    kols   => '',
    sql    => '',
    view   => '',
    params => {},
    raw    => 0,
    quote  => 0,
    hdr    => 1,
    help   => 0,
    man    => 0,
);

GetOptions(
    'debug|d'           => \$OPTS{debug},
    'dir:s'             => \$OPTS{dir},
    'cols|c:s'          => \$OPTS{cols},
    'kols|k:s'          => \$OPTS{kols},
    'hdr|h:s'           => \$OPTS{hdr},
    'raw|r'             => \$OPTS{raw},
    'sql|s:s'           => \$OPTS{sql},
    'quote|q'           => \$OPTS{quote},
    'view|v:s'          => \$OPTS{view},
    'param|p:s%'        => \$OPTS{params},
    'doc|documentation' => \$OPTS{doc},
    'help'              => \$OPTS{help},
    'man'               => \$OPTS{man},
) or pod2usage(2);
pod2usage(1) if $OPTS{help};

pod2usage( -exitval => 0, -verbose => 2 ) if $OPTS{"man"};

#
# Shortcut for myself to recreate the documentation
# without having to remember how it was done.
#
if ( $OPTS{doc} ) {
    system("$pod2md < $0 >README.md");
    exit 0;
}


###################################################
#
# Run the Main Program
#
###################################################

#
# Check whether we are to show the columns
#
if ( "" ne $OPTS{cols} || "" ne $OPTS{kols} ) {
    tbl_columns;
    exit 0;
}

#
# Optionally, load view
#
if ( "" ne $OPTS{view} ) {
    view_select;
    exit 0;
}

#
# Do a select
#
if ( "" ne $OPTS{sql} ) {
    tbl_select $OPTS{sql};
    exit 0;
}


###################################################
#
# Connect to the "Database"
#
###################################################

sub dbi_connect {
    $dbh = DBI->connect(
        "dbi:CSV:",
        undef, undef,
        {   f_ext        => ".csv/r",
            f_encoding   => 'utf-8):via(File::BOM',    # a hack around BOM
            f_dir        => $OPTS{dir},
            csv_eol      => "\r\n",
            csv_sep_char => ",",
            RaiseError   => 1,
            raw_header   => 1,
        }
    ) or die "Cannot connect: $DBI::errstr";
}


###################################################
#
# Disconnect from the "Database"
#
###################################################

sub dbi_disconnect {
    $sth->finish;
    $dbh->disconnect;
}


###################################################
#
# Show the columns available in the table
#
###################################################

sub tbl_columns {
    dbi_connect;

    my $table = $OPTS{kols};
    if ( "" ne $OPTS{cols} ) {
        $table = $OPTS{cols};
    }

    $sth = $dbh->prepare("select * from $table where 1=0");
    $sth->execute();

    my $res = $sth->{NAME};

    # Decide whether to print columns
    # alphabetically sorted or
    # in original order
    my @sres = ( "" ne $OPTS{cols} ? sort @$res : @$res );

    for my $r (@sres) {
        print $r . "\n";
    }

    dbi_disconnect;
}


###################################################
#
# Run using a view
#
# A View is a file containing an sql statement
#
###################################################

sub view_select {
    my $sql = "";

    my $file = $OPTS{view};
    open( INFO, $file ) or die("Could not open  file.");

    foreach my $line (<INFO>) {
        next if $line =~ /^#/;
        next if $line =~ /^$/;

        $sql .= $line . " ";
    }
    close(INFO);

    tbl_select $sql;
}


###################################################
#
# Run using an sql query from the command line
#
# Also invoked when running from a view, after
# parsing that view's sql statement.
#
# Parameters:
#
#   The SQL statement
#
###################################################

sub tbl_select {
    my $sql = shift;

    $sql = parse_sql $sql;

    if ( $OPTS{debug} ) {
        print STDERR "\n$sql\n\n";
    }

    dbi_connect;

    $sth = $dbh->prepare($sql);
    $sth->execute();

    my @cols;           # The column names
    my $tbl_results;    # The tabular result
    my @arr_results;    # The array result for raw output

    tie my (%hash_row), "Tie::IxHash";    # A tied hash for a row

    #
    # Iterate over the result set
    #
    while ( my $row = $sth->fetchrow_hashref() ) {
        #
        # If we did not yet read the column headers,
        # we do so now.
        #
        if ( !@cols ) {
            @cols = @{ $sth->{NAME} };
            if ( $OPTS{raw} && $OPTS{hdr} ) {
                push @arr_results, [@cols];
            }
            else {
                $tbl_results = Text::Table->new(@cols);
            }
        }

        #
        # Read one row of the result set
        #
        if ( $OPTS{raw} ) {
            my @arow;
            foreach my $col (@cols) {
                push @arow, $row->{$col};
            }
            push @arr_results, [@arow];
        }
        else {
            $tbl_results->add( map( { $hash_row{$_} = $row->{$_} } @cols ) );
        }
    }

    #
    # Print the table
    #
    if ( $OPTS{raw} ) {
        my $csv = Text::CSV->new();

        foreach my $row (@arr_results) {
            my $csv = Text::CSV->new( { always_quote => $OPTS{quote}, } );
            $csv->combine(@$row);
            print $csv->string;
            print "\n";
        }
    }
    else {
        if ( defined $tbl_results ) {
            print $tbl_results;
        }

    }


    #
    # Disconnect
    #
    dbi_disconnect;
}


###################################################
#
# Parse the SQL statemtn
#
# The params option can contain additional
# command line parameters to be used with
# the -p command line switch. These are key-value
# pairs that are parsed into the statement.
#
# Also, if there are optional parameters such as
# _WHERE_, they are either replaced by their
# equivalent command line parameter given by
# -p, or, if none is given, they are removed.
#
# Finally, the whole sql statement is returned
# concatenated into one line.
#
# Parameters:
#
#   The SQL statement
#
###################################################

sub parse_sql {
    my $sql = shift;

    foreach my $key ( keys %{ $OPTS{params} } ) {
        my $val = %{ $OPTS{params} }{$key};
        $sql =~ s/$key/$val/g;
    }

    #
    # Parse out optional parameters
    # should they not have been given
    # up to now
    #
    $sql =~ s/_WHERE_//g;

    return $sql;
}


exit 0;


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

csvdb interprets all .csv files in the data directory as tables.
So if, for example, you do this:

  ./csvdb.pl -s "select distinct id, name from employee order by name"

Then this expects to find a file employee.csv in the data directory,
with at least a header line containing something like id, name, which
are going to be the column headers.

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

  ./cvsdb.pl -v employees.sql

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

=cut

