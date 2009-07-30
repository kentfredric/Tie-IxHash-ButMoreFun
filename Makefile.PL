
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Tie-IxHash-ButMoreFun',
  NAME      => 'Tie::IxHash::ButMoreFun',
  AUTHOR    => 'Kent\ Fredric\ \<kentnl\@cpan\.org\>',
  ABSTRACT  => 'A\ user\-friendly\ wrapper\ to\ a\ Tie\:\:IxHash\ object\ to\ fill\ some\ use\ case\ holes\.',
  VERSION   => '1.0921113',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0',
    "namespace::autoclean" => '0',
    "Tie::IxHash" => '0',
    "Test::use::ok" => '0.02',
    "Moose" => '0.65',
  },
);
