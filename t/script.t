use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $script = do 'script/screenorama' or plan skip_all => $@;
my($server, @start);

is $script->listen, 'http://*:5000', 'default listen';
is $script->stdin, 0, 'default stdin';
is $script->single, 0, 'default single';
is $script->conduit, 'pty', 'default conduit';

$server = $script->server(foo => 123);
is $server->stdin, 0, 'server stdin';
is $server->single, 0, 'server single';
is $server->conduit, 'pty', 'server conduit';
is $server->{foo}, 123, 'optional server arguments';

Mojo::Util::monkey_patch('Mojolicious', 'start' => sub { @start = @_ });
eval { $script->run };
like $@, qr{Usage:}, 'invalid usage';

$script->run('foo', '--', 'ls', '-l');
is_deeply [@start[1,2,3]], ['daemon', '-l', 'http://*:5000'], 'start() args';
is $start[0]->program, 'ls', 'program: ls';
is_deeply $start[0]->program_args, ['-l'], 'program_args: -l';

done_testing;
