package CSVdb;

=pod

=head1 NAME

CSVdb - Main Program Routine.

=head1 DESCRIPTION

This class provides for the main program routine of CSVdb.

You can use it like so:

    # Initialize, or rather, reuse from elsewhere...

    my $CSVdb = CSVdb->new;
    $CSVdb->run;

=head1 METHODS

=cut

use warnings;
use strict;


binmode STDOUT, ":utf8";
use utf8;

use Data::Dump "pp";
use Pod::Usage;
use File::Basename;

use Text::Table;
use Text::CSV;
use Tie::IxHash;
use DBI;
use File::BOM;

use Cwd qw(abs_path);

use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };

use CSVdb::TConfig;
use CSVdb::TCache;


###################################################
#
# Logger
#
###################################################


use Log::Log4perl qw(get_logger :levels);


#
# Fields
#
has result => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    lazy    => 1,
);

has cfg   => ( is => 'rw' );
has cache => ( is => 'rw' );


#
# Constructor
#
sub BUILD {
    my ( $self, $arg_ref ) = @_;

    #
    # Initialize the Logger
    #
    Log::Log4perl->init_once( $ENV{ROOT} . '/log4p.ini' );

    my $log = Log::Log4perl::get_logger("CSVdb");

    if ( exists $ENV{LOGLEVEL} && "" ne $ENV{LOGLEVEL} ) {
        $log->level( uc $ENV{LOGLEVEL} );
    }

    #
    # Initialize the Cache
    #
    $self->cache( CSVdb::TCache->new );
}


###################################################
#
# Main Program Routine
#
###################################################

sub run {
    my ($self) = @_;

    $self->log->debug("> Run");

    if ( $self->cfg->get("refresh") ) {
        $self->cache->flush();
        $self->cfg->remove("refresh");
    }

    #
    # Set default values
    #
    $self->cfg->set( "debug", 0 ) if !defined $self->cfg->get("debug");
    $self->cfg->set( "dir", "./data/$ENV{DATASET}/data" )
        if !defined $self->cfg->get("dir");
    $self->cfg->set( "cols", "" ) if !defined $self->cfg->get("cols");
    $self->cfg->set( "kols", "" ) if !defined $self->cfg->get("kols");
    $self->cfg->set( "sql",  "" ) if !defined $self->cfg->get("sql");
    $self->cfg->set( "view", "" ) if !defined $self->cfg->get("view");
    $self->cfg->set( "params", [] ) if !defined $self->cfg->get("params");
    $self->cfg->set( "raw",   0 ) if !defined $self->cfg->get("raw");
    $self->cfg->set( "quote", 0 ) if !defined $self->cfg->get("quote");
    $self->cfg->set( "hdr",   1 ) if !defined $self->cfg->get("hdr");

    #
    # Convert array of params into hash
    #
    my %params;
    foreach
        my $param ( @{ $self->cfg->get( "params", { 'as_array' => 1 } ) } )
    {
        my ( $key, $val ) = split( /=/, $param );
        $params{$key} = $val;
        $self->cfg->set( "params", \%params );
    }

    #
    # Optionally, show columns
    #
    if ( "" ne $self->cfg->get("cols") || "" ne $self->cfg->get("kols") ) {
        $self->tbl_columns();
        return;
    }


    #
    # Optionally, load view
    #
    if ( "" ne $self->cfg->get("view") ) {
        $self->view_select();
        return;
    }

    #
    # Do a select
    #
    if ( "" ne $self->cfg->get("sql") ) {
        $self->tbl_select( $self->cfg->get("sql") );
        return;
    }

    $self->log->debug("< Run");
}


###################################################
#
# Show the columns available in the table
#
###################################################

sub tbl_columns {
    my ($self) = @_;

    $self->log->trace("> Table Columns");

    $self->dbi_connect();

    my $table = $self->cfg->get("kols");

    if ( "" ne $self->cfg->get("cols") ) {
        $table = $self->cfg->get("cols");
    }

    my $dbh = $self->cfg->get("dbh");

    my $sth = $dbh->prepare("select * from $table where 1=0");

    $self->cfg->set( "sth", $sth );

    $sth->execute();

    my $res = $sth->{NAME};

    # Decide whether to print columns
    # alphabetically sorted or
    # in original order
    my @sres = ( "" ne $self->cfg->get("cols") ? sort @$res : @$res );

    for my $r (@sres) {
        #print $r . "\n";
        $self->result( $self->result . $r . "\n" );
    }

    $self->dbi_disconnect();

    $self->log->trace("< Table Columns");
}


###################################################
#
# Connect to the "Database"
#
###################################################

sub dbi_connect {
    my ($self) = @_;

    $self->log->debug("> dbi_connect");

    my $dbh = DBI->connect(
        "dbi:CSV:",
        undef, undef,
        {   f_ext => ".csv/r",
            #            f_encoding   => "utf-8",
            f_encoding   => 'utf-8):via(File::BOM',    # a hack around BOM
            f_dir        => $self->cfg->get("dir"),
            csv_eol      => "\r\n",
            csv_sep_char => ",",
            RaiseError   => 1,
            raw_header   => 1,
        }
    ) or die "Cannot connect: $DBI::errstr";

    #
    # Declare stored functions (see package main below)
    #
    $dbh->do('CREATE FUNCTION rnd EXTERNAL');
    $dbh->do('CREATE FUNCTION trim_oppi EXTERNAL');
    $dbh->do('CREATE FUNCTION intl_date EXTERNAL');

    $self->cfg->set( "dbh", $dbh );

    $self->log->debug("< dbi_connect");
}


###################################################
#
# Disconnect from the "Database"
#
###################################################

sub dbi_disconnect {
    my ($self) = @_;

    $self->log->debug("> dbi_disconnect");

    my $dbh = $self->cfg->get("dbh");
    my $sth = $self->cfg->get("sth");

    if ( defined $sth ) {
        $sth->finish;
    }

    if ( defined $dbh ) {
        $dbh->disconnect;
    }

    #
    # Do a little cleanup
    #
    # TODO: Monitor better for memory consumption
    # instead of reducing MaxConnectionsPerChild.
    #
    $self->cfg->remove("dbh");
    $self->cfg->remove("sth");

    $self->log->debug("< dbi_disconnect");
}


###################################################
#
# Run using a view
#
# A View is a file containing an sql statement
#
###################################################

sub view_select {
    my ($self) = @_;

    $self->log->debug("> view_select");

    my $view = $self->cfg->get("view");

    my $sql = $self->cache->get(
        $view,
        sub {
            my $result;

            open( INFO, $view ) or die("Could not open file $view: $!");
            foreach my $line (<INFO>) {
                next if $line =~ /^#/;
                next if $line =~ /^$/;

                $result .= $line . " ";
            }
            close(INFO);

            return $result;
        }
    );

    $self->tbl_select($sql);

    $self->log->debug("< view_select");
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
    my ( $self, $sql ) = @_;

    $self->log->debug("> tbl_select");

    $sql = $self->parse_sql($sql);

    if ( $self->cfg->get("debug") ) {
        print STDERR "\n$sql\n\n";
    }

    my $cache_key
        = $self->cache->key( $sql . " -- " . $self->cfg->get("dir") );
    my $cache_result = $self->cache->get($cache_key);

    if ( defined $cache_result ) {
        $self->result($cache_result);
        $self->log->debug("< tbl_select (cached)");

        return;
    }

    $self->dbi_connect();

    my $dbh = $self->cfg->get("dbh");
    my $sth = $dbh->prepare($sql);

    $self->cfg->set( "sth", $sth );

    $self->log->debug("> Executing SQL select");
    $sth->execute();
    $self->log->debug("< Executing SQL select");

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
            if ( $self->cfg->get("raw") && $self->cfg->get("hdr") ) {
                push @arr_results, [@cols];
            }
            else {
                $tbl_results = Text::Table->new(@cols);
            }
        }

        #
        # Read one row of the result set
        #
        if ( $self->cfg->get("raw") ) {
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
    if ( $self->cfg->get("raw") ) {
        my $csv = Text::CSV->new();

        foreach my $row (@arr_results) {
            my $csv
                = Text::CSV->new(
                { always_quote => $self->cfg->get("quote"), } );
            $csv->combine(@$row);
            $self->result( $self->result . $csv->string . "\n" );
        }
    }
    else {
        if ( defined $tbl_results ) {
            $self->result( "" . $tbl_results );
        }

    }

    untie %hash_row;


    $self->cache->set( $cache_key, $self->result );

    #
    # Disconnect
    #
    $self->dbi_disconnect();

    $self->log->debug("< tbl_select");
}


###################################################
#
# Parse the SQL statemnt
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
    my ( $self, $sql ) = @_;

    $self->log->debug("> parse_sql");

    $self->cfg->dump();

    my $params = $self->cfg->get("params");

    if ( ref $params eq 'HASH' ) {
        foreach my $key ( keys %$params ) {
            my $val = %{ $self->cfg->get("params") }{$key};
            if ( defined $val ) {
                $sql =~ s/$key/$val/g;
            }
        }
    }

    #
    # Parse out optional parameters
    # should they not have been given
    # up to now
    #
    $sql =~ s/_WHERE_//g;
    $sql =~ s/_ORDER_//g;

    $self->log->debug("< parse_sql");

    return $sql;
}


sub describe {
    my ($self) = @_;

    return $self->cfg;
}


sub dump {
    my ($self) = @_;
    $Data::Dumper::Terse = 1;
    $self->log->debug( sub { Data::Dumper::Dumper( $self->describe ) } );
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;


###################################################
#
# Stored Functions for CSVdb
#
###################################################

package main;

sub rnd {
    my ( $self, $sth, $n ) = @_;

    $n =~ s/,//;    # remove thousands comma
                    #$n += 0.05;            # want to round up (as number)
                    #$n =~ s/\.(\d).*/.$1/; # perform the rounding (as string)

    $n = int( $n + 0.5 );    # Would round to full number

    return $n;
}

sub trim_oppi {
    my ( $self, $sth, $oppi ) = @_;

    $oppi =~ s/^0//;         # remove leading 0

    return $oppi;
}

sub intl_date {
    my ( $self, $sth, $date ) = @_;

    if ( $date =~ m!(\d\d)/(\d\d)/(\d\d\d\d)! ) {
        $date = "$3-$1-$2";
    }
    return $date;
}

1;
