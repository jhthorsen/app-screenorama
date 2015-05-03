package App::screenorama;

=head1 NAME

App::screenorama - Application output to websocket stream

=head1 VERSION

0.03

=head1 DESCRIPTION

This program allow you to pipe STDOUT and STDERR from a program over a
websocket.

=begin html

<img src="https://github.com/jhthorsen/app-screenorama/raw/master/resources/app-screenorama.gif" alt="screenshot">

=end html

=head2 Protocol

The data transmitted over the websocket connection is JSON in each frame:

=over 4

=item * Startup

  {"program":$str,"program_args":...}

Same as L</program> and L</program_args>.

=item * Output

  {"output":$str}

Comes after each time the program emit data. NOTE: There's no guaranty
that it will be emitted on newline.

=item * Exit

  {"exit_value":$int,"signal":$int}

The exit value of the application. The websocket will be closed after
you see this.

=item * Error

  {"error":$str}

If something goes wrong with the application or other operating
system errors.

=back

=head1 SYNOPSIS

=head2 Server

  # let others connect to the running program
  $ screenorama --listen http://*:5000 --single -- 'while sleep 1; do echo "hey!"; done'

  # pipe the output on incoming request
  $ screenorama -- ls -l

=head2 Client

Connect a browser to L<http://localhost:5000> or L<ws://localhost:5000> to
see the output.

=cut

use Mojo::Base -strict;

our $VERSION = '0.03';

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
