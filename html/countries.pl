###################################################
#
# Output List of Countries
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

my $view   = "views/countries.sql";
my $data   = "data";
my $params = [];                      # Allow only these params
my $name   = "";                      # Don't link this column
my $noclip = "1";                     # Don't put clipboard actions


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
    noclip => $noclip,
);

$thtml->run;
