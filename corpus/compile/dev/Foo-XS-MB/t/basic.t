use strict;
use warnings;
use Test::More tests => 1;
use Foo::XS;

is Foo::XS::fooish(), 42, 'Foo::XS::fooish() = 42';
