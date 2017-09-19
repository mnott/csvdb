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

use CSVdb;
use CSVdb::TConfig;



use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };

#
# The cache
#
has cache => (
    is      => 'rw',
    traits  => ['Hash'],
    isa     => 'HashRef',
    lazy    => 0,
    default => sub { {} },
);

has cfg      => ( is => 'rw' );
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


sub key {
    my ( $self, $var, $prefix ) = @_;

    my $md5hash = md5_hex($var);

    return "CSVdb::" . $prefix . "::" . $md5hash;
}


sub set {
    my ( $self, $var, $val, $arg_ref ) = @_;

    $self->log->debug( "+ Cache Set : $var; (" . length($val) . ")" );

    if ( defined $val ) {
        $val = compress( encode( "utf8", $val ) );
    }

    $self->memcache->set( $var, $val );
}

sub get {
    my ( $self, $var, $arg_ref ) = @_;

    my $val = $self->memcache->get($var);

    my $result = ( defined $val ) ? "Hit :" : "Miss:";

    if ($result) { $val = decode( "utf8", uncompress($val) ); }

    $self->log->debug("+ Cache $result $var");

    return $val;
}


sub delete {
    my ( $self, $var, $arg_ref ) = @_;

    $self->memcache->delete($var);
}



sub refresh {
    my ( $self ) = @_;

    $self->log->debug("Refresh Cache");

    $self->memcache->flush_all( );
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
