###################################################
#
# Output List for Product
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

my $view   = "views/product.sql";
my $data   = "data";
my $params = ["PRODUCT"];           # Allow only these params
my $name   = "Product";             # Don't link this column


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
