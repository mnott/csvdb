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

use Data::Dump "pp";

use CSVdb::TUtils qw (t_case);
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

my $datasets = $ds->datasets;

print <<EOF;
Content-type: text/html

<!DOCTYPE html>
<html>
<link rel="stylesheet" type="text/css" href="styles.css" />
</head>
<body>
<div id="content" align="left">
<table cellpadding="5" cellspacing="0" border="0" bordercolor="black" width="100%">
<tr class="h"><td>&nbsp;</td><td class="l">Datasets</td></tr>
EOF

for my $dataset ( @$datasets ) {
    my $description = $ds->describe($dataset);

    print <<EOF
    <tr><td>&nbsp;</td></td><td><a href="/index.pl?dataset=$dataset" target="_top">$description</a></td>
EOF
}

print <<EOF
</table>
</div>

    <script>
    function resizeIframe(iframeID) {
        var iframe = window.parent.document.getElementById(iframeID);
        var container = document.getElementById('content');
        iframe.style.height = container.offsetHeight + 'px';
    }
    resizeIframe("datasets");
    </script>
</body>
</html>
EOF





