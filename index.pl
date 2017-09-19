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
# Run
#
###################################################

my $req = shift;

$req = Apache2::Request->new($req);

my $debug   = $req->param("debug");
my $dataset = $req->param("dataset");

$dataset = "cloud_consolidated_pipeline" if !defined $dataset;

print <<EOF;
Content-type: text/html

<!DOCTYPE html>
<html>

  <head>
    <title>CVSdb</title>
  </head>

  <frameset cols = "10%,80%" frameborder="0">
    <frame name = "countries" src = "html/view.pl?debug=$debug&dataset=$dataset&view=countries" />
    <frame name = "main"      src = "html/view.pl?debug=$debug&dataset=$dataset&view=country&country=UKI" />
    <noframes>
      <body>Your browser does not support frames.</body>
    </noframes>
  </frameset>

</html>

EOF
