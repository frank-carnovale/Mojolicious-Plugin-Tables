package Blah;
use Mojo::Base 'Mojolicious';
use StuffDB;

sub startup {
  my $self = shift;

  $self->plugin(Tables => { connect_info=>["dbi:SQLite:$ENV{EXAMPLEDB}", '', ''] });

}

1;
