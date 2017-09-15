package CSVdb::TUtils;

=pod

=head1 NAME

CSVdb::Utils - Shared Utilities

=head1 DESCRIPTION

This class provides for some utility functions shared elsewhere.


=head1 METHODS

=cut

use warnings;
use strict;

binmode STDOUT, ":utf8";
use utf8;
use Carp qw(carp cluck croak confess);
use feature qw(say);
use Data::Dump "pp";
use Pod::Usage;
use File::Basename;

use Exporter 'import';

use XML::LibXML;
use XML::LibXML::PrettyPrint;

our @EXPORT_OK = qw/ t_as_string t_split /;

sub t_as_string {
    my $self = shift;
    my $res  = "";
    my $pp   = XML::LibXML::PrettyPrint->new( indent_string => "  " );

    foreach my $arg (@_) {
        if ( !defined $arg ) {
            $res .= "";
        }
        else {
            if ( $res ne "" ) {
                $res .= ", ";
            }
            $res .= pp($arg);
        }
    }
    return $res;
}


sub t_split {
    my ( $sep, $str ) = @_;

    my @arr = split( $sep, $str );

    @arr = grep /\S/, @arr;
    return @arr;
}

1;
