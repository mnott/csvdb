package CSVdb::TCache;

=pod

=head1 NAME

CSVdb::TCache - Frontend to memcached

=head1 DESCRIPTION

This class provides for a cache wrapper on top of memcached.
If memcached is not there, the class will  just use an internal
hash.

=head1 METHODS

=cut

use warnings;
use strict;

binmode STDOUT, ":utf8";
use utf8;
use Carp qw(carp cluck croak confess);
use feature qw(say);
use Data::Dump "pp";

#use Cache::Memcached::Fast;
use Cache::Memcached;
use Compress::Zlib;
use Encode qw(encode decode);
use Digest::MD5 qw(md5_hex);

use Storable qw(freeze thaw read_magic);

use CSVdb;
use CSVdb::TConfig;



use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };


#
# Fields
#
has memcache => ( is => 'rw' );


#
# Constructor
#
sub BUILD {
    my ( $self, $arg_ref ) = @_;

    my $memd = new Cache::Memcached {
        'servers'            => ['127.0.0.1:11211'],
        'compress_threshold' => 10_000,
    };

    $self->memcache($memd);
}


###################################################
#
# Get a cache key
#
# Create a unique cache key using an md5 hash over
# some value. This is useful if, for example, we
# want to cache the results of an SQL query, and
# we want to use the query as a cache key. Instead
# of using the whole query, we create a hash.
#
# This function can be called separately from get
# and set; they use it implicitly, too.
#
#
# $var: The name to create a cache key for
#
###################################################

sub key {
    my ( $self, $var ) = @_;

    my $md5hash = md5_hex($var);

    return "CSVdb::" . $md5hash;
}


###################################################
#
# Get something from the cache
#
#
# $var: The cache key to use (will implicitly call
#       key() on $var)
#
# $val: The value to cache. Can be a scalar or ref
#
###################################################

sub set {
    my ( $self, $var, $val ) = @_;

    $self->log->debug( "+ Cache Set : $var; (" . length($val) . ")" );

    if ( defined $val ) {
        if ( ref($val) ) {
            #
            # If we have a reference, we use Storable::freeze
            #
            $val = freeze($val);
        }
        else {
            #
            # Otherwise we still have to encode our string
            # to avoid eventual wide utf8 characters
            $val = encode( "utf8", $val );
        }
        #
        # Once frozen or encoded, we compress the string
        #
        $val = compress($val);
    }

    #
    # Finally, we set the string into the cache.
    #
    $self->memcache->set( $self->key($var), $val );
}



###################################################
#
# Write something to the cache
#
# $var: The cache key to retrieve (will implicitly
#       call key() on $var)
#
# $callback: An optional function reference that
#            should be called if nothing is found
#            in the cache. If defined, it will be
#            called, and its result will be cached.
#
# Sample call:
#
#     my $datasets = $self->cache->get(
#       "datasets",
#       sub {
#           my @datasets = []; # Read values
#
#           return \@datasets;
#       }
#   );
#
###################################################

sub get {
    my ( $self, $var, $callback ) = @_;

    #
    # Try getting something from the cache
    #
    my $val = $self->memcache->get( $self->key($var) );

    my $result = ( defined $val ) ? "Hit :" : "Miss:";

    $self->log->debug("+ Cache $result $var");

    if ( defined $val ) {
        #
        # If we have found something in the cache,
        # we anyway have to decompress it.
        #
        $val = uncompress($val);

        if ( read_magic($val) ) {
            #
            # If we found something that was frozen using
            # Storable::freeze, Storable::read_magic will
            # tell us so, and then we use Storable::thaw
            # to unfreeze it. This should be the case for
            # anything but scalar values.
            #
            $val = thaw($val);
        }
        else {
            #
            # If the value was not frozen, it was still
            # encoded to work around wide utf8 characters,
            # so we have to decode it in this case.
            #
            $val = decode( "utf8", $val );
        }
    }

    #
    # Check if we have not retrieved anything, but were
    # given a function reference to call. Typically, that
    # reference would fetch the value to cache from some
    # other place.
    #
    if ( !defined $val && defined $callback ) {
        #
        # Call the function reference
        #
        $val = $callback->($var);

        #
        # Cache the value
        #
        $self->set( $var, $val );
    }

    return $val;
}


###################################################
#
# Delete something from the cache
#
# $var: The variable to remove from the cache
#
###################################################

sub delete {
    my ( $self, $var ) = @_;

    $self->memcache->delete($var);
}



###################################################
#
# Flush the cache
#
###################################################

sub flush {
    my ($self) = @_;

    $self->log->debug("Refresh Cache");

    $self->memcache->flush_all();
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
