use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'App::screenorama',
  ABSTRACT_FROM => 'lib/App/screenorama.pm',
  VERSION_FROM => 'lib/App/screenorama.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Applify' => 0.05,
    'Mojolicious' => '3.40',
    'Mojo::IOLoop::ReadWriteFork' => '0.04',
  },
  BUILD_REQUIRES => {
    'Test::More' => '0.90',
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/App-screenorama',
      bugtracker => 'https://github.com/jhthorsen/app-screenorama/issues',
      repository => 'https://github.com/jhthorsen/app-screenorama',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
  EXE_FILES => ['script/screenorama'],
);
