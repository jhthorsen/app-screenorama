package App::screenorama;

=head1 NAME

App::screenorama - Application output to websocket stream

=head1 VERSION

0.02

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

use Mojo::Base 'Mojolicious';
use Mojo::IOLoop::ReadWriteFork;

our $VERSION = '0.02';

=head1 ATTRIBUTES

=head2 conduit

  $str = $self->conduit;
  $self = $self->conduit($str);

Defaults to "pty". Can also be set to "pipe".

=head2 program

  $str = $self->program;
  $self = $self->program($str);

Path, name of to the application to run or the whole command.

=head2 program_args

  $array_ref = $self->program_args;
  $self = $self->program_args([qw( --option )]);

Arguments to L</program>.

=head2 single

  $bool = $self->single;
  $self = $self->single($bool);

Set this to true if you want all incoming requests to connect to
one stream. False means start L</program> on each request.

Default: false.

=head2 stdin

Allow standard input from websocket to L</program>.

=cut

has conduit => 'pty';
has program => '';
has program_args => sub { +[] };
has single => 0;
has stdin => 0;
has _fork => sub {
  my $self = shift;
  my $fork = Mojo::IOLoop::ReadWriteFork->new;
  my $plugins = $self->plugins;

  $fork->on(close => sub {
    $plugins->emit(output => { exit_value => $_[1], signal => $_[2] });
    $plugins->has_subscribers('output') or Mojo::IOLoop->stop;
  });
  $fork->on(error => sub {
    $plugins->emit(output => { error => $_[1] });
    $plugins->has_subscribers('output') or Mojo::IOLoop->stop;
  });
  $fork->on(read => sub {
    $plugins->emit(output => { output => $_[1] });
  });
  $fork->start(
    conduit => $self->conduit,
    program => $self->program,
    program_args => $self->program_args,
  );

  $fork;
};

=head1 METHODS

=head2 startup

Used to start the web server.

=cut

sub startup {
  my $self = shift;
  my $r = $self->routes;

  $self->renderer->classes([__PACKAGE__]);

  $r->get('/' => sub {
    my $c = shift;
    my $url = $c->req->url->to_abs;
    my $stream_base = $url->base;

    $stream_base->scheme($url->scheme =~ /https/ ? 'wss' : 'ws');
    $c->render(
      cmd => join(' ', $self->app->program, @{ $self->app->program_args }),
      stream_base => $stream_base,
      template => 'index',
    );
  });

  if($self->single) {
    $self->_fork;
    $r->websocket('/stream' => \&_single_stream);
  }
  else {
    $r->websocket('/stream' => \&_stream_on_request);
  }
}

sub _single_stream {
  my $c = shift;
  my $plugins = $c->app->plugins;
  my $fork = $c->app->_fork;
  my $cb;

  $cb = sub {
    $c->send({ json => $_[1] });
    defined $_[1]->{error} or defined $_[1]->{exit_value} or return;
    $plugins->unsubscribe(output => $cb);
    $c->finish;
  };

  Mojo::IOLoop->stream($c->tx->connection)->timeout(60);

  $c->send({ json => { program => $c->app->program, program_args => $c->app->program_args } });
  $c->on(json => sub { $fork->write(chr $_[1]->{key}); }) if $c->app->stdin;
  $c->on(finish => sub { $plugins->unsubscribe(output => $cb); });
  $plugins->on(output => $cb);
}

sub _stream_on_request {
  my $c = shift;
  my $fork = Mojo::IOLoop::ReadWriteFork->new;
  my $app = $c->app;

  Scalar::Util::weaken($c);
  Mojo::IOLoop->stream($c->tx->connection)->timeout(60);
  $c->on(json => sub { $fork->write(chr $_[1]->{key}); }) if $c->app->stdin;
  $c->on(finish => sub { $fork->kill($ENV{SCREENORAMA_KILL_SIGNAL} || 15); });
  $c->stash(fork => $fork);
  $c->send({ json => { program => $app->program, program_args => $app->program_args } });

  $fork->on(close => sub {
    $c->send({ json => { exit_value => $_[1], signal => $_[2] } });
    $c->stash(fork => undef)->finish;
  });
  $fork->on(error => sub {
    $c->send({ json => { error => $_[1] } });
    $c->stash(fork => undef)->finish;
  });
  $fork->on(read => sub {
    $c->send({ json => { output => $_[1] } });
  });

  $fork->start(program => $app->program, program_args => $app->program_args, conduit => $app->conduit);
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;

__DATA__
@@ index.html.ep
% my $stdin = $self->app->stdin;
<!DOCTYPE html>
<html>
<head>
  <title>screenorama - <%= $cmd %></title>
  %= stylesheet begin
body { background: #111; padding: 8px; }
body, pre { font-size: 13px; font-family: monospace; color: #eee; margin: 0; padding: 0; }
input { position: absolute; left: -600px; }
  % end
  %= javascript begin
var color = { // from http://flatuicolors.com/
  '30': '#000000',
  '31': '#c0392b',
  '32': '#2ecc71',
  '33': '#f1c40f',
  '34': '#48a2df',
  '35': '#9b59b6',
  '36': '#1abc9c',
  '37': '#ecf0f1',
};

var replaceColors = function(match, a, b) {
  console.log([a,b]);
  var closing = replaceColors.span ? '</span>' : '';
  var style = [];

  replaceColors.span = false;

  if(!a && typeof b == 'undefined') { return closing; } // regular

  if(color[b]) style.push('color: ' + color[b]);
  else if(color[a]) style.push('background-color: ' + color[a]);

  if(a == 1) { style.push('font-weight: bold'); }
  else if(a == 4) { style.push('text-decoration: underline'); }

  replaceColors.span = true;
  return closing + '<span style="' + style.join(';') + '">';
};

window.onload = function() {
  var ws = new WebSocket('<%= $stream_base %>/stream');
  var pre = document.getElementsByTagName('pre')[0];
  var cmd = document.getElementById('cmd');
  var cursor = document.getElementById('cursor');

  cursor.visible = true;

  setInterval(
    function() {
      cursor.style.opacity = cursor.visible ? 0.02 : 1.0;
      cursor.visible = !cursor.visible;
    },
    700
  );

  ws.onopen = function() { console.log('CONNECT'); };
  ws.onclose = function() { console.log('DISCONNECT'); };
  ws.onmessage = function(event) {
    console.log(event.data);
    var data = JSON.parse(event.data);
    var backspace = 0;
    if(typeof data.output !== 'undefined') {
      cursor.parentElement.removeChild(cursor);
      pre.innerHTML += data.output
        .replace(/\u001B\(B/g, function() { return ''; })
        .replace(/\u001B\[(?:0?(\d?);(\d\d)|(0?)|(\d\d))m/g, replaceColors);
      pre.appendChild(cursor);
    }
    window.scrollTo(0, document.body.scrollHeight);
  };

  if(cmd) {
    document.onclick = function() { cmd.focus(); };
    cmd.focus();
    cmd.onkeydown = function(e) {
      console.log(e.which);
      if(e.which == 8) ws.send('{"key":' + 0x7f + '}');
    };
    cmd.onkeypress = function(e) {
      e.preventDefault();
      ws.send('{"key":' + e.keyCode + '}');
      if(e.keyCode == 13) cmd.value = '';
    };
  }
};
  % end
</head>
<body>
<pre>
$ <%= $cmd %>
% if($stdin) {
<span id="cursor">&#9602;</span>
% }
</pre>
% if($stdin) {
<input id="cmd" placeholder="Type input to the program">
% }
</body>
</html>
