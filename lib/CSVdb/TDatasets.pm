package CSVdb::TDatasets;

=pod

=head1 NAME

CSVdb::TDatasets - Wrapper for Datasets

=head1 DESCRIPTION

This class provides for a wrapper around the datasets.

=head1 METHODS

=cut

use warnings;
use strict;

binmode STDOUT, ":utf8";
use utf8;

use File::Slurp qw( read_dir );
use File::Spec::Functions qw( catfile );
use File::Basename;

use CSVdb::TSession;
use CSVdb::TCache;
use CSVdb::TUtils qw (t_case);

use Data::Dump "pp";

use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };


#
# Fields
#
has req      => ( is => 'rw' );    # HTTP request
has ses      => ( is => 'rw' );    # HTTP session
has cache    => ( is => 'rw' );    # The cache
has datasets => ( is => 'rw' );    # The datasets array
has dataset  => ( is => 'rw' );    # The chosen dataset


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
    # Initialize the cache
    #
    $self->cache( CSVdb::TCache->new );

    #
    # Initialize the HTTP session
    #
    $self->ses( CSVdb::TSession->new( req => $self->req ) );

    #
    # Read the list of datasets
    #
    my $path = "$ENV{ROOT}data";

    my @ignore = ( "$path/input", "$path/current" );

    my $datasets = $self->cache->get(
        "datasets",
        sub {
            $self->log->debug("+ Reading datasets from file system");

            my @sub_dirs = grep {-d} map { catfile $path, $_ } read_dir $path;

            my @datasets;

            foreach my $sub_dir (sort @sub_dirs) {
                next if grep( /^$sub_dir$/, @ignore);
                my $location = fileparse($sub_dir);
                push( @datasets, $location );
            }

            return \@datasets;
        }
    );
    $self->datasets($datasets);


    #
    # Try to read the data set from the parameter
    #
    my $dataset = $self->req->param("dataset");

    #
    # If we don't have it in the request, try to find it
    # in the session
    #
    if ( !defined $dataset ) {
        $dataset = $self->ses->get("dataset");
    }

    #
    # If we don't have it in the session, choose the
    # first one we had read from disk (or cache).
    #
    if ( !defined $dataset ) {
        $dataset = $datasets->[0];
        $self->ses->set( "dataset", $dataset );
    }

    $self->dataset($dataset);

    #
    # Now we should have both $self->dataset, with the
    # current dataset, and also $self->datasets, with
    # all data sets, as members.
    #

    #
    # Try to read the delta mode
    #
    my $delta = $self->req->param("delta");
    if (!defined $delta) {
        $delta = $self->ses->get("delta");
    }
    if (!defined $delta) {
        $delta = 0;
        $self->ses->set("delta", $delta)
    }
}


sub describe {
    my ( $self, $location ) = @_;

    my $description = $location;
    $description =~ s/_/ /g;
    $description = t_case($description);

    return $description;
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
