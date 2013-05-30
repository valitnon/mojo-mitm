package Mojo::MITM;

use Mojo::Base -base;

use Getopt::Long 2.13     qw(GetOptionsFromArray);
use Mojo::MITM::Proxy;

our $VERSION = "0.006";
$VERSION = eval $VERSION;

has mitm_args => undef;

sub _show_usage {
  warn <<"EOF";

mojo-mitm - Non-blocking Man-In-The-Middle (MITM) SSL capable HTTP proxy, based
            on excellent Mojolicious framework. You can intercept HTTP(S)
            requests/responses and/or modify them on the fly.

Usage:
        mojo-mitm [-l <address:port>][...]

    -h|-help
        show usage + version info

    -l|-listen=<addr:port> or -l=http://<addr:port> or -l=https://<addr:port>
        proxy listenning address:port, this option can be used multiple times
        -l http://127.0.0.1:8080   standard HTTP proxy
        -l https://127.0.0.1:8081  HTTP proxy+SSL, handy for reverse proxying
        -l 'https://127.0.0.1/?cert=/dir/srv.crt&key=/dir/srv.key'
        -l 8080               same as: -l http://127.0.0.1:8080
        -l 192.33.44.55:8080  same as: -l http://192.33.44.55:8080
        default is -l 7979

    -v|-verbosity=<n>
        verbosity level - 0...3, default=2

    -c|-client-cert=<pem_cert_file>
        will use client SSL certificate if required by server

    -k|-client-key=<pem_key_file>
        private key corresponding to the certificate given by -client-cert

    -a|-ca-dir=<directory>
        working direcotry for MITM CA generating fake certificates and
        storing CA's certificate + private key
        default is '~/.mojo-mitm'

    -p|-plugin=/path/to/Plugin.pm,p1=val1,p2=val2
        load plugin + pass given parameters to it, plugins can be used to
        modify HTTP(S) requests/responses on the fly, for more info check
        sample plugin 'plugins/PluginExample.pm'
        this option can be used multiple times

    -x|-parent-proxy=<addr:port> or -x=http://<addr:port>
        will use given <addr:port> as a parent HTTP proxy for outgoing connections

    -t|-timeout=<n>
        set inactivity timeout (in seconds) for Mojo::IOLoop, default=25

    -clone-crt
        by default MITM CA generates fake certificates only with CN=<hostname>
        set this option if you want CA to copy as much attributes from the
        original certificate as possible

    -log=<log_file>
        redirect logs to given logfile

Version: $VERSION

Copyright (c) 2013 DCIT, a.s. [http://www.dcit.cz] / Karel Miko

EOF
  exit(1);
}

sub parse_options {
  my $self = shift;
  my $args = {};
  if (@_) {
    GetOptionsFromArray(\@_,
      'h|help|?'               => sub { _show_usage },
      'l|listen=s@'            => \$args->{listen},
      'v|verbosity=n'          => \$args->{verbosity},
      'c|client-cert=s'        => \$args->{client_tls_crt},
      'k|client-key=s'         => \$args->{client_tls_key},
      'a|ca-dir=s'             => \$args->{ca_dir},
      'p|plugin=s@'            => \$args->{plugins_to_load},
      'x|parent-proxy=s'       => \$args->{parent_proxy},
      'i|inactivity-timeout=n' => \$args->{inactivity_timeout},
      'clone-crt'              => \$args->{clone_crt},
      'log=s'                  => \$args->{log_file},
    ) or _show_usage;
    for (keys %$args) { delete $args->{$_} unless defined $args->{$_} }
  }
  else {
    warn "-- Using defaults, try --help for more info\n";
  }
  $self->mitm_args($args);
}

sub do_job {
  my $self = shift;
  my $proxy = Mojo::MITM::Proxy->new($self->mitm_args);
  $proxy->run;
}

1;
