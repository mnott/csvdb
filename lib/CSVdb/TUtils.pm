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
use Storable qw(freeze thaw read_magic);
use Scalar::Util qw(reftype);

use Exporter 'import';

use XML::LibXML;
use XML::LibXML::PrettyPrint;

our @EXPORT_OK = qw/ t_as_string t_split t_case t_serialize t_deserialize /;

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

###################################################
#
# Convert a String to Title Case.
#
# Based on the excellent work by
# Aristotle Pagaltzis and John Gruber
#
# https://github.com/ap/titlecase
#
###################################################

sub t_case {
    my @str = @_ or return;
    our @SMALL_WORD
        = qw/ (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? /;

    for (@str) {
        s{\A\s+}{}, s{\s+\z}{};

        $_ = lc $_ unless /[[:lower:]]/;

        my $apos = q/ (?: ['’] [[:lower:]]* )? /;
        my $small_re = join '|', @SMALL_WORD;

        s{
            \b _*\K (?:
                ( (?<=[ ][/\\]) [[:alpha:]]+ [-_[:alpha:]/\\]+ |   # file path or
                [-_[:alpha:]]+ [@.:] [-_[:alpha:]@.:/]+ $apos )    # URL, domain, or email
                |
                ( (?i) $small_re $apos )                           # or small word (case-insensitive)
                |
                ( [[:alpha:]] [[:lower:]'’()\[\]{}]* $apos )       # or word w/o internal caps
                |
                ( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $apos )       # or some other word
            ) (?= _* \b )
        }{
            ; defined $1 ? $1         # preserve URL, domain, or email
            : defined $2 ? lc $2      # lowercase small word
            : defined $3 ? ucfirst $3 # capitalize lower-case word
            : $4                      # preserve other kinds of word
        }exgo;

        # exceptions for small words: capitalize at start and end of title
        s{
            (?: \A [[:punct:]]*        # start of title...
            |  [:.;?!][ ]+             # or of subsentence...
            |  [ ]['"“‘(\[][ ]*     )  # or of inserted subphrase...
            \K
            ( $small_re ) \b           # ... followed by small word
        }{\u\L$1}xigo;

        s{
            \b ( $small_re )      # small word...
            (?= [[:punct:]]* \Z   # ... at the end of the title...
            |   ['"’”)\]] [ ] )   # ... or of an inserted subphrase?
        }{\u\L$1}xigo;
    }

    wantarray ? @str : ( @str > 1 ) ? \@str : $str[0];
}

sub t_serialize {
    my ($obj) = @_;

    if ( !defined reftype($obj) ) {
        return $obj;
    }
    else {
        return freeze($obj);
    }
}

sub t_deserialize {
    my ($obj) = @_;

    if ( read_magic($obj) ) {
        return thaw($obj);
    }
    else {
        return $obj;
    }
}


1;
