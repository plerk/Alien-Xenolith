use strict;
use warnings;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More tests => 3;
use File::Spec;
use File::Path qw( mkpath );
use lib File::Spec->catdir( 'corpus', 'search_path', 'lib' );
use Config;

subtest 'prep' => sub {
  plan tests => 2;
  use_ok 'Alien::Foo';
  use_ok 'Alien::Foo::Recipe';
};

subtest 'perl identifier is a directory that can be created' => sub {
  plan tests => 3;
  
  my $id = eval { Alien::Xenolith->perl_id };
  diag $@ if $@;
  ok $id, "perl_id = $id";

  my $test = File::Spec->catdir(File::HomeDir->my_home, 'test', $id);
  is scalar mkpath($test, 0, 0711), 3, "mkpath $test";

  ok -d $test, "dir exists $test";
};

subtest 'search path has at least one entry' => sub {
  plan tests => 2;
  
  local $ENV{XENOLITH_PATH} = join $Config{path_sep}, map {
    my $dir = File::Spec->catfile(File::HomeDir->my_home, $_);
    mkdir $dir;
    $dir;
  } qw( path1 path2 );
  
  my @list = eval { Alien::Foo->search_path };
  diag $@ if $@;
  is scalar @list, 4, 'search_path';
  note "search_path = $_" for @list;
  
  my $install = eval { Alien::Foo->install_path };
  diag $@ if $@;
  is $install, File::Spec->catfile(File::HomeDir->my_home, 'path1', 'Alien-Foo'), 'install_path';
};
