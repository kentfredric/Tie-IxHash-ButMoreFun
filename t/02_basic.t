use strict;
use warnings;

use Test::More tests => 9;    # last test to print

sub TIxBMF() {
  'Tie::IxHash::ButMoreFun';
}

use ok TIxBMF;

my $f = TIxBMF->new( 'hello' => 'world', 'a' => 'b', 'c' => 'd', 'e' => 'f' );
is_deeply( [ $f->all_keys ], [ 'hello', 'a', 'c', 'e', ], "Key order retention" );

$f->swap_keys( 'a', 'e' );
is_deeply( [ $f->all_keys ], [ 'hello', 'e', 'c', 'a', ], "Key order shuffling retention" );
is_deeply( [ $f->get_key_value('e') ], ['f'], "Key value retention in shuffle" );

$f->swap_values( 'a', 'e' );
is_deeply( [ $f->get_key_value('e') ], ['b'], "Key value retention in swap" );

$f->move_down('hello');

is_deeply( [ $f->all_keys ], [ 'e', 'hello', 'c', 'a', ], "Down Moves" );

$f->move_up( 'a', 10 );
is_deeply( [ $f->all_keys ], [ 'a', 'e', 'hello', 'c', ], "Up Bulkd Moves" );

$f->move_down( 'e', 10 );
is_deeply( [ $f->all_keys ], [ 'a', 'hello', 'c', 'e', ], "Down Bulk Moves" );

is_deeply( [ values %{ $f->IxHash } ], [ 'f', 'world', 'd', 'b' ], "Values are portable" );

