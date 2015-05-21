#!/usr/bin/perl

package MyWebServer;
use strict;
 
use HTTP::Server::Simple::PSGI;
use base qw(HTTP::Server::Simple::PSGI);
use IO::Socket::SSL;

 
sub accept_hook {
my $self = shift;
my $fh   = $self->stdio_handle;

$self->SUPER::accept_hook(@_);

my $newfh =
IO::Socket::SSL->start_SSL( $fh, 
    SSL_server    => 1,
    SSL_use_cert  => 1,
    SSL_cert_file => 'server.crt',
    SSL_key_file  => 'server.key',
)
or warn "problem setting up SSL socket: " . IO::Socket::SSL::errstr();

$self->stdio_handle($newfh) if $newfh;
}

sub print_banner {}

1;
