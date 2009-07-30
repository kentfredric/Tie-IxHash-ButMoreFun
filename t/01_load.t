use strict;
use warnings;

use Test::More tests => 3;
use Test::Moose;

sub classe() {
  'Tie::IxHash::ButMoreFun';
}

use ok classe;
meta_ok(classe);
new_ok(classe);
