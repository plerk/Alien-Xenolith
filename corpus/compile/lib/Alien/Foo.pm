package Alien::Foo;

use base qw( Alien::Xenolith );

sub Inline { my %h = __PACKAGE__->inline; \%h }

1;
