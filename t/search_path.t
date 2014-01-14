use strict;
use warnings;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More tests => 9;
use File::Spec;
use File::Path qw( mkpath );
use lib File::Spec->catdir( 'corpus', 'search_path', 'lib' );
use Config;

subtest 'prep' => sub {
  plan tests => 2;
  use_ok 'Alien::Foo';
  use_ok 'Alien::Foo::Recipe';
  
  my @dirs = map { File::Spec->catdir(split m{/}, $_) } qw( 
    corpus/search_path/lib/auto/Alien/Foo/E198DB4A-7C80-11E3-AEBD-2AD555543D6A
    corpus/search_path/lib/auto/Alien/Foo/E0EC54F6-7C80-11E3-B153-29D555543D6A
    corpus/search_path/lib/auto/Alien/Foo
  );
  
  eval { chmod 0555, $_ if -w $_ } for @dirs;
  
  # windows is funny... it has a read only attribute for folders,
  # but it ignores it.  At least in XP and better.
  if($^O =~ /^(MSWin32|cygwin)$/)
  {
    open(FP, '>', File::Spec->catfile( qw( corpus search_path lib auto Alien Foo _readonly )));
    close FP;
  }
  
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

subtest 'custom search path' => sub {
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

subtest 'fetch configs' => sub {
  plan tests => 1;
  
  my @configs = eval { Alien::Foo->get_configs };
  diag $@ if $@;
  is scalar @configs, 2, 'get_configs';
};

subtest 'fetch latest' => sub {
  plan tests => 6;
  
  my $alien = eval { Alien::Foo->new };
  isa_ok $alien, 'Alien::Foo';
  
  is eval { $alien->version }, '1.1.2', 'version = 1.1.2';
  diag $@ if $@;
  
  is eval { $alien->cflags }, '-IFoo', 'cflags = -IFoo';
  diag $@ if $@;

  is eval { $alien->libs }, '-lm', 'libs = -lm';
  diag $@ if $@;
  
  is eval { $alien->dlls->[0] }, 'foo2.dll', 'dlls = foo2.dll';
  diag $@ if $@;
  
  like eval { $alien->timestamp }, qr{^[1-9][0-9]*$}, 'timestamp';
  diag $@ if $@;
};

subtest 'class methods' => sub {
  plan tests => 4;
  
  my $alien = 'Alien::Foo';
  
  is eval { $alien->version }, '1.1.2', 'version = 1.1.2';
  diag $@ if $@;
  
  is eval { $alien->cflags }, '-IFoo', 'cflags = -IFoo';
  diag $@ if $@;

  is eval { $alien->libs }, '-lm', 'libs = -lm';
  diag $@ if $@;
  
  is eval { $alien->dlls->[0] }, 'foo2.dll', 'dlls = foo2.dll';
  diag $@ if $@;
  
};

subtest 'filter' => sub {

  my $alien = Alien::Foo->new(filter => sub { shift->version ne '1.1.2' });

  is eval { $alien->version }, '1.1.1', 'version = 1.1.1';
  diag $@ if $@;
  
  is eval { $alien->cflags }, '-IFoo', 'cflags = -IFoo';
  diag $@ if $@;

  is eval { $alien->libs }, '-lm', 'libs = -lm';
  diag $@ if $@;
  
  is eval { $alien->dlls->[0] }, 'foo1.dll', 'dlls = foo1.dll';
  diag $@ if $@;
};

subtest 'cmp' => sub {

  require Sort::Versions;

  my $alien = Alien::Foo->new(
    cmp => sub { 
      0 - Sort::Versions::versioncmp(
            $_[0]->version, $_[1]->version
          )
    },
  );

  is eval { $alien->version }, '1.1.1', 'version = 1.1.1';
  diag $@ if $@;
  
  is eval { $alien->cflags }, '-IFoo', 'cflags = -IFoo';
  diag $@ if $@;

  is eval { $alien->libs }, '-lm', 'libs = -lm';
  diag $@ if $@;
  
  is eval { $alien->dlls->[0] }, 'foo1.dll', 'dlls = foo1.dll';
  diag $@ if $@;
};

subtest 'config' => sub {

  require Sort::Versions;

  my $alien = Alien::Foo->new(
    config => {
      version => '2.0.0',
      cflags  => '-O3',
      libs    => '-lxml2',
      dlls    => [ 'foo3.dll' ],
    },
  );

  is eval { $alien->version }, '2.0.0', 'version = 2.0.0';
  diag $@ if $@;
  
  is eval { $alien->cflags }, '-O3', 'cflags = -O3';
  diag $@ if $@;

  is eval { $alien->libs }, '-lxml2', 'libs = -lxml2';
  diag $@ if $@;
  
  is eval { $alien->dlls->[0] }, 'foo3.dll', 'dlls = foo3.dll';
  diag $@ if $@;
};
