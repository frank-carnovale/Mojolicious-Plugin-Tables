use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::Tables',
  VERSION_FROM => 'lib/Mojolicious/Plugin/Tables.pm',
  AUTHOR       => 'Frank Carnovale <frankc@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '6.44',
                   'DBIx::Class::Schema::Loader' => '0.07045'},
  test         => {TESTS => 't/*.t'}
);
