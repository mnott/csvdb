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

use Apache2::compat;
use Apache2::Request;

use CSVdb::TUtils qw (t_case);
use CSVdb::TDatasets;
use CSVdb::TCache;


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
<script src="url.min.js"></script>
<script type="text/javascript">
    function refresh() {
        var u = new Url;
        u.query.refresh=1;
        window.location.href=u;
        window.parent.location.reload();
    }
</script>
</head>
<body>
<div id="content" align="left">
<table cellpadding="5" cellspacing="0" border="0" bordercolor="black" width="100%">
<thead><tr class="h"><td class="r"><a href="#" class="h" onclick="refresh();">&#x21bb;</a></td><td class="l">Datasets</td></tr></thead><tbody>
EOF


#
# Add a way to flush the cache
#
my $refresh = $req->param("refresh");
if ( defined $refresh ) {
    my $cache = CSVdb::TCache->new;
    $cache->flush();
}

#
# Print the datasets
#
for my $dataset ( @$datasets ) {
    my $description = $ds->describe($dataset);

    if ($dataset eq $ds->dataset) {
        print "<tr><td class=\"r\">&#10004;</td>";
    } else {
        print "<tr><td>&nbsp;</td>";
    }

    print <<EOF
    </td><td><a href="/index.pl?dataset=$dataset" target="_top">$description</a></td>
EOF
}

print <<EOF
</tbody></table>
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





