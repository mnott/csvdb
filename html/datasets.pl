###################################################
#
# Output a list of datasets
#
# (c) 2017 Matthias Nott
#
###################################################

use strict;
use warnings;
no warnings qw(redefine);

binmode STDOUT, ":utf8";
use utf8;

use File::Slurp qw( read_dir );
use File::Spec::Functions qw( catfile );
use File::Basename;
use Apache2::compat;
use Apache2::Request;


###################################################
#
# Datasets directory
#
# Datasets are subdirectories under this directory.
# They typically contain
#
# data/         Directory holding csv files
# views/        Directory holding views
# columns.json  File specifying output columns
# views.json    File specifying the views
#
###################################################

my $path = "$ENV{ROOT}/data";

my $req = shift;

$req = Apache2::Request->new( $req );

my @sub_dirs = grep { -d } map { catfile $path, $_ } read_dir $path;

my %datasets;

foreach my $sub_dir (@sub_dirs) {
    my $location    = fileparse($sub_dir);
    my $description = $location;
    $description =~ s/_/ /g;
    $description =~ s/([\w']+)/\u\L$1/g
    $datasets{$location} = $description;
}

print STDERR $datasets{$_}, "\n" for sort keys %datasets;



sub title_case {
my @small_words = qw( (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? );
my $small_re = join '|', @small_words;

my $apos = qr/ (?: ['’] [[:lower:]]* )? /x;

while ( <> ) {
    s{\A\s+}{}, s{\s+\z}{};
    $_ = lc $_ if not /[[:lower:]]/;
    s{
        \b (_*) (?:
            ( (?<=[ ][/\\]) [[:alpha:]]+ [-_[:alpha:]/\\]+ |   # file path or
              [-_[:alpha:]]+ [@.:] [-_[:alpha:]@.:/]+ $apos )  # URL, domain, or email
            |
            ( (?i: $small_re ) $apos )                         # or small word (case-insensitive)
            |
            ( [[:alpha:]] [[:lower:]'’()\[\]{}]* $apos )       # or word w/o internal caps
            |
            ( [[:alpha:]] [[:alpha:]'’()\[\]{}]* $apos )       # or some other word
        ) (_*) \b
    }{
        $1 . (
          defined $2 ? $2         # preserve URL, domain, or email
        : defined $3 ? "\L$3"     # lowercase small word
        : defined $4 ? "\u\L$4"   # capitalize word w/o internal caps
        : $5                      # preserve other kinds of word
        ) . $6
    }xeg;


    # Exceptions for small words: capitalize at start and end of title
    s{
        (  \A [[:punct:]]*         # start of title...
        |  [:.;?!][ ]+             # or of subsentence...
        |  [ ]['"“‘(\[][ ]*     )  # or of inserted subphrase...
        ( $small_re ) \b           # ... followed by small word
    }{$1\u\L$2}xig;

    s{
        \b ( $small_re )      # small word...
        (?= [[:punct:]]* \Z   # ... at the end of the title...
        |   ['"’”)\]] [ ] )   # ... or of an inserted subphrase?
    }{\u\L$1}xig;

    # Exceptions for small words in hyphenated compound words
    ## e.g. "in-flight" -> In-Flight
    s{
        \b
        (?<! -)                 # Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (in-flight)
        ( $small_re )
        (?= -[[:alpha:]]+)      # lookahead for "-someword"
    }{\u\L$1}xig;

    ## # e.g. "Stand-in" -> "Stand-In" (Stand is already capped at this point)
    s{
        \b
        (?<!…)                  # Negative lookbehind for a hyphen; we don't want to match man-in-the-middle but do want (stand-in)
        ( [[:alpha:]]+- )       # $1 = first word and hyphen, should already be properly capped
        ( $small_re )           # ... followed by small word
        (?! - )                 # Negative lookahead for another '-'
    }{$1\u$2}xig;

    print "$_";
}
}