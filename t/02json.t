use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $testdir;
BEGIN {
    use File::Basename 'dirname';
    $testdir = dirname(__FILE__);
    $ENV{EXAMPLEDB} = "$testdir/example.db";
}
use lib "$testdir/blah/lib";

my $t = Test::Mojo->new('Blah');

$t->get_ok('/'                      => 'App starts');

$t->get_ok('/tables/artist.json'    => 'Artist json query succeeds');

#note "GOT",  explain $t->tx->res->json;

$t->json_has('/data'                => 'json response has data');
$t->json_is ('/data/1/name', 'Michael Jackson',
                                    => 'data includes Michael Jackson');

done_testing();
