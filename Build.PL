
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'Tie::IxHash::ButMoreFun',
  license       => 'perl',
  dist_abstract => "A\ user\-friendly\ wrapper\ to\ a\ Tie\:\:IxHash\ object\ to\ fill\ some\ use\ case\ holes\.",
  dist_name     => "Tie\-IxHash\-ButMoreFun",
  dist_author   => [
"Kent\ Fredric\ \<kentnl\@cpan\.org\>",
  ],
  requires      => {
    "Test::More" => '0',
    "namespace::autoclean" => '0',
    "Tie::IxHash" => '0',
    "Test::use::ok" => '0.02',
    "Moose" => '0.65',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
