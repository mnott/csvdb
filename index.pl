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

use Apache2::compat;
use Apache2::Request;

use CSVdb::THTML;
use CSVdb::TDatasets;

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

my $req = Apache2::Request->new(shift);

my $ds = CSVdb::TDatasets->new( req => $req, );

my $dataset = $ds->dataset;

my $debug   = $req->param("debug");

my $delta   = $req->param("delta");

if(! defined $delta || $delta eq "") {
  $delta = 0;
}

if ( !defined $dataset ) {
    print <<EOF;
Content-type: text/html

<!DOCTYPE html>
<html>
  <head>
    <title>CVSdb</title>
  </head>
  <body>
  <h1>No datasets found.</h1>
  </body>
</html>
EOF
}
else {
    $debug = 0 if !defined $debug;

    print <<EOF;
Content-type: text/html

<!DOCTYPE html>
<html>

  <head>
    <title>CVSdb</title>
  </head>

  <frameset cols = "10%,80%" frameborder="0">
    <frame name = "countries" src = "html/view.pl?debug=$debug&delta=$delta&dataset=$dataset&view=countries" />
    <frame name = "main"      src = "html/view.pl?debug=$debug&delta=$delta&dataset=$dataset&view=country&country=Spain" />
    <noframes>
      <body>Your browser does not support frames.</body>
    </noframes>
  </frameset>

</html>

EOF
}