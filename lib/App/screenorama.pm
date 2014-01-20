package App::screenorama;

=head1 NAME

App::screenorama - Application output to websocket stream

=head1 VERSION

0.01

=head1 DESCRIPTION

This program allow you to pipe STDOUT and STDERR from a program over a
websocket.

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

use Mojolicious;

our $VERSION = '0.01';

=head1 ATTRIBUTES

=head2 program

  $str = $self->program;
  $self = $self->program($str);

Path, name of to the application to run or the whole command.

=head2 program_args

  $array_ref = $self->program_args;
  $self = $self->program_args([qw( --option )]);
  $self = $self->program_args(undef);

Arguments to L</program>. Setting it to C<undef> will allow the shell to
interpret L</program>.

=head2 single

  $bool = $self->single;
  $self = $self->single($bool);

Set this to true if you want all incoming requests to connect to
one stream. False means start L</program> on each request.

Default: false.

=cut

has program => '';
has program_args => sub { +[] };
has single => 0;

=head1 METHODS

=head2 startup

Used to start the web server.

=cut

sub startup {
  my $self = shift;
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
