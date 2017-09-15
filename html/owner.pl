###################################################
#
# Output List for Owner
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
# Template Specifics
#
###################################################

my $view   = "views/owner.sql";
my $data   = "data";
my $params = ["OWNER"];           # Allow only these params
my $name   = "Opp_Owner";         # Don't link this column


###################################################
#
# Run Query
#
###################################################

my $req = shift;

my $thtml = CSVdb::THTML->new(
    req    => $req,
    view   => $view,
    data   => $data,
    params => $params,
    name   => $name,
);

$thtml->run;
