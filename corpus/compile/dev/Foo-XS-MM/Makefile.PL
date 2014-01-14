use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;

use Alien::Foo;

WriteMakefile(
  ABSTRACT => 'Perl bindings to Foo via XS',
  AUTHOR   => "Graham Ollis <plicease\@cpan.org>",
  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => "6.30",
    "Alien::Foo"          => 0,
  },
  DISTNAME => "Foo-XS",
  LICENSE  => 'perl',
  NAME     => "Foo::XS",
  VERSION  => '1.00',
  Alien::Foo->make_maker,
);

