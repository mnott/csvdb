package CSVdb::THTML;

=pod

=head1 NAME

CSVdb::HTML - Output HTML pages

=head1 DESCRIPTION

This class provides for a template wrapper to output query
results as HTML.

=head1 METHODS

=cut

use warnings;
use strict;

binmode STDOUT, ":utf8";
use utf8;
use Data::Dump "pp";

use CSVdb;
use CSVdb::TCache;
use CSVdb::TConfig;
use CSVdb::TSession;


use URL::Encode qw(url_encode_utf8);

use JSON;

use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };


#
# Fields
#
has req     => ( is => 'rw' );    # HTTP request
has ses     => ( is => 'rw' );    # HTTP session
has view    => ( is => 'rw' );    # view directory
has data    => ( is => 'rw' );    # data directory
has name    => ( is => 'rw' );    # Name of the template, ignore for links
has columns => ( is => 'rw' );    # Column Name => Metadata
has views   => ( is => 'rw' );    # View   Name => Metadata
has filters => ( is => 'rw' );    # Filter Name => Metadata
has reports => ( is => 'rw' );    # Report Name => Metadata
has csvdb   => ( is => 'rw' );    # The CSVdb engine
has cfg     => ( is => 'rw' );    # The Configuration
has noclip  => ( is => 'rw' );    # Don't put clipboard actions
has cache   => ( is => 'rw' );    # The cache


#
# Hold the column positions as key, colum meta-
# data as values. This is populated while reading
# the table header, so that later when reading the
# potentially long table, we can quickly decide if
# we have to do some alignment, link, etc.
#
has positions => (
    is      => 'rw',
    traits  => ['Hash'],
    isa     => 'HashRef',
    lazy    => 0,
    default => sub { {} },
);


#
# Holds the column sums, the column name as a key,
# colum sum as value - for those columns that have
# a sum
#
has sums => (
    is      => 'rw',
    traits  => ['Hash'],
    isa     => 'HashRef',
    lazy    => 0,
    default => sub { {} },
);


#
# Constructor
#
sub BUILD {
    my ( $self, $arg_ref ) = @_;

    #
    # Initialize the Logger
    #
    Log::Log4perl->init_once( $ENV{ROOT} . '/log4p.ini' );

    my $log = Log::Log4perl::get_logger("CSVdb");

    if ( exists $ENV{LOGLEVEL} && "" ne $ENV{LOGLEVEL} ) {
        $log->level( uc $ENV{LOGLEVEL} );
    }

    #
    # Initialize the cache
    #
    $self->cache( CSVdb::TCache->new );

    #
    # Initialize the configuration holder
    #
    $self->cfg( CSVdb::TConfig->new );

    #
    # Initialize the CSVdb engine.
    #
    $self->csvdb( CSVdb->new( cfg => $self->cfg ) );

    #
    # Initialize the HTTP session
    #
    $self->ses( CSVdb::TSession->new( req => $self->req ) );

    #
    # Read the dataset
    #
    my $dataset = $self->get_param( "dataset", "" );
    $self->log->debug("+ Using dataset: $dataset");


    #
    # Read debug mode
    #
    $self->cfg->set( "debug", $self->get_param( "debug", $ENV{'DEBUG'} ) );
    $self->log->debug( "+ Using debug mode: " . $self->cfg->get("debug") );

    #
    # Read delta mode
    #
    $self->cfg->set( "delta", $self->get_param( "delta", 0 ) );
    $self->log->debug( "+ Using delta mode: " . $self->cfg->get("delta") );


    #
    # Read the column definitions
    #
    $self->columns(
        $self->read_json("$ENV{ROOT}/data/$dataset/columns.json") );

    #
    # Read the view definitions
    #
    $self->views( $self->read_json("$ENV{ROOT}/data/$dataset/views.json") );


    #
    # Early exit if we cannot read the views
    #
    if ( ref $self->views ne 'HASH' ) {
        $self->log->error("Dataset $dataset not found.");
        return;
    }


    #
    # Read the filter definitions
    #
    $self->filters(
        $self->read_json("$ENV{ROOT}/data/$dataset/filters.json") );

    #
    # Read the report definitions
    #
    $self->reports(
        $self->read_json("$ENV{ROOT}/data/$dataset/reports.json") );

    #
    # Parse the parameters
    #

    $self->parse_params;

    #
    # Read the View
    #
    my $view = $self->views->{ $self->req->param("view") };

    #
    # Name is used to identify the column which
    # we don't want to add hyperlinks to (itself)
    #
    $self->name( $view->{name} );

    #
    # noclip is used to not show a clipboard copy icon
    # left of a row.
    #
    $self->noclip( $view->{noclip} );

    #
    # Read the Request Parameters
    #
    $self->cfg->set( "view",
        $ENV{ROOT} . "/data/$dataset/views/" . $view->{view} );
    $self->cfg->set( "dir", $ENV{ROOT} . "/data/$dataset/data/" );


    my @request_params;
    foreach my $param ( @{ $view->{params} } ) {
        my $val = $self->req->param($param);
        if ( defined $val ) {
            push @request_params, $param . "=" . $val;
            $self->ses->set( $param, $val );
        }
        else {
            my $pval = $self->get_param($param);
            if ( !defined $pval ) {
                push @request_params, $param . "=";
                $self->ses->remove($param);
            }
            else {
                push @request_params, $param . "=" . $pval;
                $self->ses->set( $param, $pval );
            }

        }
    }

    if ( $self->get_param( "delta", 0 ) != 0 ) {
        push @request_params, "_DELTA_=_d";
    }
    else {
        push @request_params, "_DELTA_=";
    }

    $self->cfg->append( "params", \@request_params );
}


#
# Read JSON file
#
sub read_json {
    my ( $self, $json ) = @_;

    if ( !-e $json ) {
        return decode_json("[]");
    }

    my $result = $self->cache->get(
        $json,
        sub {
            my $result;

            $self->log->debug("+ Read  File: $json");
            {
                local $/;    # Enable 'slurp' mode
                open my $fh, "<", "$json" || die "Error opening: $json: $!";
                $result = <$fh> || die "Error opening: $json: $!";
                close $fh;
            }

            return $result;
        }
    );

    return decode_json($result);
}


#
# Main Function
#
sub run {
    my ($self) = @_;

    #
    # Run the query
    #
    $self->csvdb->run;
    my @results = split "\n", $self->csvdb->result();


    ###################################################
    #
    # Output HTML
    #
    ###################################################

    $self->start_html;

    #
    # Instantiate a CSV parser that we'll need later
    #
    my $csv = Text::CSV->new();


    my $lines = 0;

    foreach my $row (@results) {
        $csv->parse($row);
        my @fields = $csv->fields();

        if ( !$lines ) {
            $self->print_table_header( \@fields );
        }
        else {
            $self->print_table_line( \@fields, $lines );
        }

        $lines++;
    }


    $self->end_html;

}


#
# Print the HTML header
#
sub start_html {
    my ($self) = @_;

    print <<'HERE';
Content-Type:text/html; charset=UTF-8

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link rel="stylesheet" type="text/css" href="styles.css" />
<script src="clipboard.min.js"></script>
<script src="url.min.js"></script>
<script type="text/javascript">
    function sort(column) {
        var u = new Url;
        u.query.order=column;
        window.location.href=u;
    }
    function filter(name, url) {
        var resp = prompt(name, "");
        if (resp != null && resp != "") {
            url = url.replace("__VALUE__", encodeURIComponent(resp));
            document.location.href=url;
        }
    }
    function delta(delta) {
        var u = new Url;
        u.query.delta=delta;
        window.location.href=u;
    }
    function navigate(url, parameter, value, refresh) {
        if(refresh) {
            setTimeout(function(){ window.location.reload(); }, 1000);
        }

        url = updateQueryStringParameter(url, parameter, value);

        window.parent.main.location.href=url;
    }
    function updateQueryStringParameter(uri, key, value) {
        var re = new RegExp("([?&])" + key + "=.*?(&|$)", "i");
        var separator = uri.indexOf('?') !== -1 ? "&" : "?";
        if (uri.match(re)) {
          return uri.replace(re, '$1' + key + "=" + value + '$2');
        }
        else {
          return uri + separator + key + "=" + value;
        }
    }

</script>
</head>
<body>
HERE

    #
    # Hack: if we do not have $self->name, we probably did not
    # find the dataset, so we just issue a refresh
    #
    if ( !defined $self->name ) {
        $self->ses->set( "dataset", "" );
        $self->cache->flush();
        my $dataset = $self->get_param( "dataset", "" );
        print <<'HERE';
    <script>
        var url = window.parent.parent.location.href;
        url = updateQueryStringParameter(url, "dataset", "");
        window.parent.parent.location.href = url;
    </script>

HERE
    }

    #
    # Optionally, output the dataset selection
    #
    if ( defined $self->name && $self->name eq "Countries" ) {
        print <<'HERE';
<iframe
   id="datasets"
   src="datasets.pl?debug=$debug"
   frameborder="0"
   width="100%"
   marginheight="0"
   marginwidth="0"
   scrolling="no"
></iframe>
HERE
    }

    if ( defined $self->name && $self->name eq "Countries" ) {
        if (   ( defined $self->filters && scalar( @{ $self->filters } ) > 0 )
            || ( defined $self->reports && scalar( @{ $self->reports } ) > 0 )
            )
        {
            print <<'HERE';
<div align="left">
<div class="dropdown">
  <button class="dropbtn">v</button>
  <div class="dropdown-content">
HERE

            if ( defined $self->filters && scalar( @{ $self->filters } ) > 0 )
            {
                print "<span>Filters</span>\n";
                for my $i ( 0 .. scalar( @{ $self->filters } ) - 1 ) {
                    my $filter_definition = $self->filters->[$i];
                    my $label             = $filter_definition->{"label"};
                    my $url               = $filter_definition->{"url"};
                    my $parameter         = $filter_definition->{"parameter"};
                    my $value             = $filter_definition->{"value"};
                    my $refresh           = $filter_definition->{"refresh"};
                    my $html
                        = "<a onclick=\"navigate("
                        . $url . ",'"
                        . $parameter . "', '"
                        . $value . "', "
                        . $refresh
                        . ");\" rel=\"noreferrer\">"
                        . $label . "</a>";
                    print "$html\n";
                }
            }

            if ( defined $self->reports && scalar( @{ $self->reports } ) > 0 )
            {
                print "<span>Reports</span>\n";
                for my $i ( 0 .. scalar( @{ $self->reports } ) - 1 ) {
                    my $report_definition = $self->reports->[$i];
                    my $label             = $report_definition->{"label"};
                    my $url               = $report_definition->{"url"};
                    my $target            = $report_definition->{"target"};
                    my $description = $report_definition->{"description"};
                    if ( !defined $description ) {
                        $description = "";
                    }
                    my $html
                        = "<a href=\""
                        . $url
                        . "\" target=\""
                        . $target
                        . "\" rel=\"noreferrer\" title=\""
                        . $description . "\">"
                        . $label . "</a>";
                    print "$html\n";
                }
            }

            print <<'HERE';
  </div>
</div>
HERE
        }
    }

    print "<table ";

    if ( defined $self->name && $self->name ne "Countries" ) {
        print "id=\"fulltable\"";
    }

    print
        " cellpadding=\"5\" cellspacing=\"0\" border=\"0\" bordercolor=\"black\" width=\"100%\">";
}


#
# Print the HTML footer
#
sub end_html {
    my ($self) = @_;

    print <<'HERE';

</table>
</div>

    <script>
    var clipboard = new Clipboard('.clippy');

    clipboard.on('success', function(e) {
        console.log(e);
    });

    clipboard.on('error', function(e) {
        console.log(e);
    });

HERE

    my $sums = $self->sums;

    foreach my $sum ( keys %{$sums} ) {
        my $value = $sums->{$sum};
        $value = reverse join ".", ( reverse $value ) =~ /(\d{1,3})/g;

        print "    // Column Header " . $sum . "=" . $value . "\n";
        print "    var span = document.getElementById('$sum');\n";
        print "    while(span.firstChild) {\n";
        print "      span.removeChild(span.firstChild);\n";
        print "    }\n";
        print "    span.appendChild(document.createTextNode('";
        print $value;
        print "'));\n\n";
    }

    print <<'HERE';

    </script>
</body>
<html>
HERE
}


sub get_param {
    my ( $self, $param, $default ) = @_;

    my $result = $self->req->param($param);

    if ( defined $result ) {
        $self->log->debug(
            "+ Value for $param found in parameter: " . $result );
        $self->ses->set( $param, $result );
    }
    else {
        $result = $self->ses->get($param);
        if ( defined $result ) {
            $self->log->debug(
                "+ Value for $param found in session  : " . $result );
        }
    }

    if ( !defined $result ) {
        if ( !defined $default ) {
            $default = "";
        }
        $self->log->debug("+ Value for $param not found. Using $default.");
        if ( defined $default ) {
            $result = $default;
        }
    }

    return $result;

}


#
# Parse the parameters
#
sub parse_params {
    my ($self) = @_;

    #
    # Parameter handling
    #
    $self->cfg->set( "raw", 1 );

    #
    # Order Handling
    #
    # (Using the Session to store its current value)
    #
    my $param_order_col = $self->req->param("order"); # order col from Req
    my $sess_order_col  = $self->ses->param("order"); # order col from Session
    my $sess_order_dir
        = $self->ses->param("order_dir");    # order direction from Session

    if ( defined $param_order_col ) {
        $self->log->debug( "+ Order from Parameter: " . $param_order_col );


        my $column_definition
            = $self->get_column_definition_by_name($param_order_col);

        my $default_order
            = ( defined $column_definition )
            ? $column_definition->{default_order}
            : "asc";

        $self->log->debug( "+ Default Order for "
                . $param_order_col . ": "
                . $default_order );

        if ( defined $sess_order_col ) {
            $self->log->debug( "+ Order from Session: " . $sess_order_col );

            # We have an order in the session, so let's compare
            # If it si the same one from the parameter. If so,
            # we reverse the order direction
            if ( $param_order_col eq $sess_order_col ) {
                if ( defined $sess_order_dir ) {
                    $self->log->debug(
                        "+ Order dir from Session: " . $sess_order_dir );

                    $sess_order_dir
                        = ( $sess_order_dir eq "desc" ) ? "asc" : "desc";
                }
                else {
                    $sess_order_dir = $default_order;
                }
            }
            else {
                # We don't have an order in the session, so
                # we take the one from the parameter.
                $sess_order_col = $param_order_col;
                $sess_order_dir = $default_order;
            }
        }
        else {
            # We did not yet have an order in the session,
            # so we take the order from the parameter. It
            # is a new order, so we logically use what we
            # find in the default_order as order direction.
            $sess_order_col = $param_order_col;
            $sess_order_dir = $default_order;
        }


    }
    else {
        #
        # Nothing received through the parameter, so we have
        # to only check for the default order, should we not
        # have any.
        #
        if ( defined $sess_order_col ) {
            my $column_definition
                = $self->get_column_definition_by_name($sess_order_col);

            $self->log->debug("+ Only from session: $sess_order_col ");

            if ( !defined $sess_order_dir ) {
                $sess_order_dir
                    = ( defined $column_definition )
                    ? $column_definition->{"default_order"}
                    : "asc";
            }
        }
    }

    #
    # If we still don't know it, we use defaults.
    #
    $sess_order_col = "tcv"  unless defined $sess_order_col;
    $sess_order_dir = "desc" unless defined $sess_order_dir;

    #
    # Now we have $sess_order_col and $sess_order_dir. We
    # set it back into the session for future use.
    #
    $self->ses->set( "order",     $sess_order_col );
    $self->ses->set( "order_dir", $sess_order_dir );

    $self->log->debug(
        "+ Order now in Session: $sess_order_col $sess_order_dir");

    #
    # Construct the order string
    #
    my $order_str = " ORDER BY " . $sess_order_col . " " . $sess_order_dir;

    #
    # Set it into the Configuration, for the CSVdb engine to pick
    # it up eventually.
    #
    $self->cfg->append( "params", "_ORDER_=$order_str" );
}


#
# Get a column definition by name
#
sub get_column_definition_by_name {
    my ( $self, $column_name ) = @_;

    if ( defined $self->columns && ref $self->columns eq 'HASH' ) {
        my %column_definitions = %{ $self->columns };
        my $column_definition  = $column_definitions{"$column_name"};
        if ( defined $column_definition ) {
            return $column_definition;
        }
    }

    return;    # This return is important: implicit undef
}


#
# Register the a column into the positions hash. This is
# done while reading the header (print_table_header), and
# will help us later (print_table_line) to quickly check if
# there is anything special to be done for a column at a
# given position - such as alignment, creating a link, etc.
#
sub register_column {
    my ( $self, $column_name, $column_position ) = @_;

    my $positions = $self->positions;

    my $column_definition
        = $self->get_column_definition_by_name($column_name);

    if ( defined $column_definition ) {
        $column_definition->{"name"} = $column_name;
        $positions->{$column_position} = $column_definition;
    }
}

sub sum_column {
    my ( $self, $column_name, $add_to ) = @_;

    my $sum = $self->sums->{ uc($column_name) };
    if ( !defined $sum ) {
        $sum = 0;
    }
    $sum += $add_to;
    $self->sums->{ uc($column_name) } = $sum;
}


#
# Print the table header
#
sub print_table_header {
    my ( $self, $fields ) = @_;

    my $column = 0;

    print "<thead><tr class=\"h\">";

    #
    # Delta: &#8710;
    # All  : &#8704;
    #
    if ( $self->name ne "Countries" ) {
        if ( $self->get_param( "delta", 0 ) == 0 ) {
            print
                "<td class=\"r\"><a href=\"#\" class=\"h\" onclick=\"delta(1);\">&#8710;</a></td>";
        }
        else {
            print
                "<td class=\"r\"><a href=\"#\" class=\"h\" onclick=\"delta(0);\">&#8704;</a></td>";
        }
    }
    else {
        print "<td class=\"r\">&nbsp;</td>";
    }

    if ( $self->noclip ) {
        print "<td>&nbsp;</td>";
    }
    else {
        print
            "<td class=\"clippy\" data-clipboard-target=\"#fulltable\" style=\"top:0px;font-size:11px\">&#128203;</td>\n";
    }

    foreach my $field (@$fields) {

        if ( defined $self->columns ) {
            $self->register_column( $field, $column );
        }

        my $column_definition = $self->positions->{$column};

        my $name;
        my $align;
        my $header;
        my $sum;
        my $url;
        my $search_url;
        my $header_url;
        my $header_target;

        if ( defined $column_definition ) {
            $name          = $column_definition->{"name"};
            $align         = $column_definition->{"align"};
            $url           = $column_definition->{"url"};
            $header        = $column_definition->{"header"};
            $search_url    = $column_definition->{"search_url"};
            $header_url    = $column_definition->{"header_url"};
            $header_target = $column_definition->{"header_target"};

            $sum = $column_definition->{"sum"};
            if ( defined $sum && $sum eq "true" ) {
                $self->sum_column( $header, 0 );
            }
        }

        my $c
            = ( defined $align )
            ? substr( $align, 0, 1 )
            : "l";

        my $search_header = ( defined $header ) ? $header : $name;

        my $search_link
            = ( defined $search_url && $self->name ne "Countries" )
            ? "oncontextmenu='javascript:filter(\""
            . $search_header . "\",\""
            . $search_url
            . "\");return false;'"
            : "oncontextmenu='javascript:return false;'";

        if ( $self->name ne "Countries" ) {
            print "<td class=\"" . $c . "\" $search_link >";

            print $self->build_url(
                {   name   => $name,
                    field  => $field,
                    text   => $field,
                    url    => $header_url,
                    target => $header_target,
                    header => $header,
                    sum    => $sum,
                    css    => "h",
                }
            );

            print "</td>\n";
        }
        else {
            print "<td>Countries</td>";
        }

        $column++;
    }
    print "</tr></thead><tbody>\n";
}


#
# Print one line of a table.
#
sub print_table_line {
    my ( $self, $fields, $line ) = @_;

    my $column = 0;

    if ( $self->noclip ) {
        print "<tr><td>&nbsp;</td><td>&nbsp;</td>\n";
    }
    else {
        print
            "<tr id=\"l$line\" ><td>&nbsp;</td><td class=\"clippy\" data-clipboard-target=\"#l$line\">&#128203;</td>\n";
    }

    foreach my $field (@$fields) {
        my $column_definition = $self->positions->{$column};

        my $align;
        my $target;
        my $url;
        my $url2;
        my $name;

        if ( defined $column_definition ) {
            $align  = $column_definition->{"align"};
            $target = $column_definition->{"target"};
            $url    = $column_definition->{"url"};
            $url2   = $column_definition->{"url2"};
            $name   = $column_definition->{"name"};

            my $sum = $column_definition->{"sum"};
            if ( defined $sum && $sum eq "true" ) {
                $self->sum_column( $name, $field );
            }
        }

        my $c
            = ( defined $align )
            ? substr( $align, 0, 1 )
            : "l";

        print "<td class=\"" . $c . "\">";

        my @fields = ($field);

        if ( defined $url && defined $url2 ) {
            my $strl = length($field);

            my $lpart = substr( $field, 0, $strl / 2 );
            my $rpart = substr( $field, length($lpart) );

            $fields[0] = $lpart;
            $fields[1] = $rpart;
        }
        else {
            $fields[0] = $field;
        }

        if ( defined $url ) {
            print $self->build_url(
                {   name   => $name,
                    field  => $field,
                    text   => $fields[0],
                    url    => $url,
                    target => $target
                }
            );

            if ( $#fields > 0 ) {
                if ( defined $url ) {
                    print $self->build_url(
                        {   name   => $name,
                            field  => $field,
                            text   => $fields[1],
                            url    => $url2,
                            target => $target
                        }
                    );
                }
                else {
                    print $fields[1];
                }
            }
        }
        else { print $field; }
        print "</td>\n";

        $column++;
    }
    print "</tr>\n";
}


sub build_url {
    my ( $self, $args ) = @_;

    my $name   = $args->{name};
    my $url    = $args->{url};
    my $target = $args->{target};
    my $field  = $args->{field};
    my $text   = $args->{text};
    my $header = $args->{header};
    my $sum    = $args->{sum};
    my $css    = $args->{css};

    my $result = "";

    # && defined $self->name
    #           && defined $name
    #           && $name ne $self->name
    #
    # Shortcut if we don't even have an url
    #

    if (!defined $url
        || (  !defined $self->req->param("search")
            && defined $self->name
            && defined $name
            && $name eq $self->name )
        )
    {
        if ( defined $header ) {
            $result .= $header;
        }
        else {
            $result .= $field;
        }

        return $result;
    }


    my $string = $field;

    #
    # Remove wide characters for Spanish/Turkish...
    # This requires a "like"
    #
    $string =~ s/[^\x00-\x7f]/%/g;

    #
    # Replace braces. Also requires a "like"
    #
    $string =~ s/\(/%/g;
    $string =~ s/\)/%/g;

    my $urlfield = url_encode_utf8($string);
    ( my $turl = $url ) =~ s|__VALUE__|$urlfield|g;

    if ( $turl =~ m/(.*)__PARAMS__(.*)/ ) {
        my $m1  = $1;
        my $m2  = $2;
        my $val = %{ $self->cfg->get("params") }{ uc( $self->name ) };
        $val = $m2 unless defined $val;
        $turl = $1 . $val . $2;
    }

    $result .= "<a href=\"$turl\"";

    if ( defined $css ) {
        $result .= " class=\"$css\"";
    }

    if ( defined $target ) {
        $result .= " target=\"$target\"";
    }
    $result .= ">";

    if ( defined $header ) {
        if ( defined $sum && $sum eq "true" ) {
            $result
                .= "<span id=\"$header\" title=\"$header\">"
                . $header
                . "</span>";
        }
        else {
            $result .= $header;
        }
    }
    else {
        $result .= $text;
    }

    $result .= "</a>";


    return $result;

}




no Moose;
__PACKAGE__->meta->make_immutable;

1;
