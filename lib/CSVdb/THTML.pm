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

use Apache2::compat;
use Apache2::Request;
use Apache::Session::DB_File;

use CSVdb;
use CSVdb::TConfig;
use CSVdb::TSession;


use URL::Encode qw(url_encode_utf8);

use JSON;

use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };


has req     => ( is => 'rw' );    # HTTP request
has ses     => ( is => 'rw' );    # HTTP session
has view    => ( is => 'rw' );    # view directory
has data    => ( is => 'rw' );    # data directory
has name    => ( is => 'rw' );    # Name of the template, ignore for links
has columns => ( is => 'rw' );    # Column Name => Metadata
has views   => ( is => 'rw' );    # View   Name => Metadata
has csvdb   => ( is => 'rw' );    # The CSVdb engine
has cfg     => ( is => 'rw' );    # The Configuration
has noclip  => ( is => 'rw' );    # Don't put clipboard actions


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
    # Initialize the configuration holder
    #
    $self->cfg( CSVdb::TConfig->new );

    #
    # Initialize the CSVdb engine.
    #
    $self->csvdb( CSVdb->new( cfg => $self->cfg ) );

    #
    # Get the Request handle
    #
    $self->req( Apache2::Request->new( $self->req ) );

    #
    # Register the HTTP session
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
    # Read the column definitions
    #
    $self->columns(
        $self->read_json("$ENV{ROOT}/data/$dataset/columns.json") );

    #
    # Read the view definitions
    #
    $self->views( $self->read_json("$ENV{ROOT}/data/$dataset/views.json") );





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
        }
    }
    $self->cfg->append( "params", \@request_params );
}


#
# Read JSON file
#
sub read_json {
    my ( $self, $json, $prefix ) = @_;

    my $cache_key = $self->csvdb->cache->key( $json, "json" );
    my $result = $self->csvdb->cache->get($cache_key);
    if ( !defined $result ) {
        $self->log->debug("+ Reading $json");
        {
            local $/;    # Enable 'slurp' mode
            open my $fh, "<", "$json";
            $result = <$fh>;
            close $fh;
        }
        $self->csvdb->cache->set( $cache_key, $result );
    }
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
    my $odd   = 0;

    foreach my $row (@results) {
        $csv->parse($row);
        my @fields = $csv->fields();

        if ( !$lines ) {
            $self->print_table_header( \@fields );
        }
        else {
            $odd = $odd ? 0 : 1;
            $self->print_table_line( \@fields, $odd, $lines );
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
Content-type: text/html

<html>
<head>
<link rel="stylesheet" type="text/css" href="styles.css" />
<script src="clipboard.min.js"></script>
<script src="url.min.js"></script>
<script type="text/javascript">
    function sort(column) {
        var u = new Url;
        u.query.order=column;
        window.location.href=u;
    }
    function refresh() {
        var u = new Url;
        u.query.refresh=1;
        window.location.href=u;
    }
</script>
</head>
<body>
HERE

#
# Optionally, output the dataset selection
#
    if ( $self->name eq "Countries" ) {
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

    print <<'HERE';
<div align="left">
<table cellpadding="5" cellspacing="0" border="0" bordercolor="black" width="100%">
HERE
}


#
# Print the HTML footer
#
sub end_html {
    my ($self) = @_;

    print <<'HERE';

<tr class="h"><td>&nbsp;</td></tr>

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
        $self->log->debug("+ Value for $param not found. Using $default.");
        $result = $default;
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
    # Add a way to refresh the cache
    #
    my $refresh = $self->req->param("refresh");
    $self->cfg->set( "refresh", $refresh );

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

    if ( defined $self->columns ) {
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


#
# Print the table header
#
sub print_table_header {
    my ( $self, $fields ) = @_;

    my $column = 0;

    print "<tr class=\"h\"><td onclick='refresh();'>&nbsp;</td>\n";

    foreach my $field (@$fields) {

        if ( defined $self->columns ) {
            $self->register_column( $field, $column );
        }

        my $column_definition = $self->positions->{$column};

        my $name;
        my $align;
        my $header;
        my $header_url;
        my $header_target;

        if ( defined $column_definition ) {
            $name          = $column_definition->{"name"};
            $align         = $column_definition->{"align"};
            $header        = $column_definition->{"header"};
            $header_url    = $column_definition->{"header_url"};
            $header_target = $column_definition->{"header_target"};
        }

        my $c
            = ( defined $align )
            ? substr( $align, 0, 1 )
            : "l";

        print "<td class=\"" . $c . "\">";

        print $self->build_url(
            {   name   => $name,
                field  => $field,
                url    => $header_url,
                target => $header_target,
                header => $header,
                css    => "h",
            }
        );

        print "</td>\n";

        $column++;
    }
    print "</tr>\n";
}


#
# Print one line of a table.
#
sub print_table_line {
    my ( $self, $fields, $odd, $line, $noclip ) = @_;

    my $column = 0;

    if ( $self->noclip ) {
        print "<tr><td>&nbsp;</td>\n";
    }
    else {
        print
            "<tr id=\"l$line\" ><td class=\"clippy\" data-clipboard-target=\"#l$line\">&nbsp;</td>\n";
    }

    foreach my $field (@$fields) {
        my $column_definition = $self->positions->{$column};

        my $align;
        my $target;
        my $url;
        my $name;

        if ( defined $column_definition ) {
            $align  = $column_definition->{"align"};
            $target = $column_definition->{"target"};
            $url    = $column_definition->{"url"};
            $name   = $column_definition->{"name"};
        }

        my $c
            = ( defined $align )
            ? substr( $align, 0, 1 )
            : "l";

        print "<td class=\"" . $c . "\">";

        if ( defined $url ) {
            print $self->build_url(
                {   name   => $name,
                    field  => $field,
                    url    => $url,
                    target => $target
                }
            );
        }
        else {
            print $field;
        }

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
    my $header = $args->{header};
    my $css    = $args->{css};

    my $result = "";

    # && defined $self->name
    #           && defined $name
    #           && $name ne $self->name
    #
    # Shortcut if we don't even have an url
    #
    if ( !defined $url
        || ( defined $self->name && defined $name && $name eq $self->name ) )
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
        $result .= $header;
    }
    else {
        $result .= $field;
    }

    $result .= "</a>";


    return $result;

}




no Moose;
__PACKAGE__->meta->make_immutable;

1;