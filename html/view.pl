###################################################
#
# Output a View
#
# (c) 2017 Matthias Nott
#
###################################################

use strict;
use warnings;
no warnings qw(redefine);

binmode STDOUT, ":utf8";
use utf8;

use CSVdb::THTML;

###################################################
#
# Run Query
#
###################################################

my $req = Apache2::Request->new(shift);

my $thtml = CSVdb::THTML->new( req => $req, );

$thtml->run;
