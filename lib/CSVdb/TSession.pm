package CSVdb::TSession;

=pod

=head1 NAME

CSVdb::TSession - HTTP Session Handler

=head1 DESCRIPTION

This class provides for a wrapper around the session.

=head1 METHODS

=cut

use warnings;
use strict;

binmode STDOUT, ":utf8";
use utf8;

use Moose;
with 'MooseX::Log::Log4perl';

use namespace::autoclean -except => sub { $_ =~ m{^t_.*} };


#
# The cache
#
has ses => ( is => 'rw' );
has req => ( is => 'rw' );


#
# Constructor
#
sub BUILD {
    my ( $self, $arg_ref ) = @_;

    #
    # Session handling
    #
    my $cookie = $self->req->header_in('Cookie');
    if ( defined $cookie ) {
        $cookie =~ s/SESSION_ID=(\w*)/$1/;
    }

    #
    # Need to wrap since server may have restarted while
    # browser with cookie is still open, leading to an
    # error thrown by DB_File
    #
    my %session;

    eval {

        tie %session, 'Apache::Session::DB_File', $cookie,
            {
            FileName      => File::Spec->tmpdir . '/sessions.db',
            LockDirectory => '/var/lock/apache2',
            };
    };
    $self->log->warn("! $@") if $@;

    #
    # Remember the session
    #
    $self->ses( \%session );

    #
    # Might be a new session, so lets give them their cookie back
    #
    my $session_id = $session{_session_id};
    $session_id = "" unless defined $session_id;
    my $session_cookie = "SESSION_ID=$session_id;";
    $self->req->header_out( "Set-Cookie" => $session_cookie );
    $self->log->info("+ HTTP $session_cookie");

}


sub set {
    my ( $self, $var, $val ) = @_;

    $self->ses->{$var} = $val;
}


sub get {
    my ( $self, $var ) = @_;

    return $self->ses->{$var};
}

sub param {
    my ( $self, $var ) = @_;

    return $self->get($var);
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
