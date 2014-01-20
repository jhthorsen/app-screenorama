use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

do 'script/screenorama' or die $@;

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200);

done_testing;
