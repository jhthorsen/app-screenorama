use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('App::screenorama');

$t->app->program('ls');
$t->app->program_args(['-l']);

$t->get_ok('/')
  ->status_is(200)
  ->text_is('title', 'screenorama - ls -l')
  ->element_exists('pre')
  ->element_exists_not('pre span.cursor')
  ->element_exists_not('input')
  ;

$t->app->stdin(1);
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('pre span#cursor')
  ->element_exists('input')
  ;

done_testing;
