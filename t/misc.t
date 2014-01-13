use strict;
use warnings;
use Test::More tests => 1;
use Config;

subtest 'config' => sub {
  ok $Config{$_}, "$_=$Config{$_}" for qw( path_sep archname );
};
