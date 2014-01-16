use strict;
use warnings;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More;
use Test::Xenolith;
use FindBin ();
use File::Spec;
use lib File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'corpus'));
use TestLib;
use Config;
use Text::ParseWords qw( shellwords );
use File::Copy qw( cp );
use File::Basename qw( basename );
use Alien::Xenolith;

plan skip_all => 'windows only test'
  unless $^O =~ /^(cygwin|MSWin32)$/;
plan skip_all => 'test requires ExtUtils::CBuilder'
  unless eval q{ use ExtUtils::CBuilder; 1 };
plan skip_all => 'test requires compiler'
  unless ExtUtils::CBuilder->new->have_compiler; 

plan tests => 3;

my $home = File::HomeDir->my_home;
my $root = File::Spec->rootdir;

subtest prep => sub {
  plan tests => 7;

  my $cb = ExtUtils::CBuilder->new;
  
  template_home_ok 'windows';

  chdir $home;
  
  my $src = File::Spec->catfile('src', 'foo.c');
  my $obj = eval { capture_note { $cb->compile(source => $src, extra_compiler_flags => '-DFOO_DLL=1') } };
  diag $@ if $@;
  
  ok -r $obj, "compile $src => $obj";

  my $dll = File::Spec->catfile('src', 'foo.dll');
  my $lib;

  if($Config{cc} =~ /cl(\.exe)?$/)
  {
    my $def = File::Spec->catfile('src', 'foo.def');
    run $Config{cc}, $obj, $def, '/link', '/dll', "/out:$dll";
    $lib = File::Spec->catfile('src','foo.lib');
  }
  else
  {
    $lib = File::Spec->catfile('src', 'libfoo.a');
    my $lddlflags = $Config{lddlflags};
    $lddlflags =~ s/\\/\//g;
    run $Config{cc}, -o => $dll, '-shared', "-Wl,--out-implib,$lib", $obj;
  }

  run 'dir', '.';
  
  ok -r $dll, "link $obj => $dll";
  ok -r $lib, "link $obj => $lib";

  mkdir 'bin';
  mkdir 'lib';
  mkdir 'include';

  my $dst = File::Spec->catfile('bin', basename $dll);
  ok cp($dll, $dst), "cp $dll => $dst";
  
  $dst = File::Spec->catfile('lib', basename $lib);
  ok cp($lib, $dst), "cp $lib => $dst";
  
  my $hdr = File::Spec->catfile('src', 'foo.h');
  $dst = File::Spec->catfile('include', 'foo.h');
  ok cp($hdr, $dst), "cp $hdr => $dst";

  if($^O eq 'cygwin')
  {
    my $al = File::Spec->catfile('lib', 'libfoo.la');
    open my $fh, '>', $al;
    print $fh "dlname='../bin/foo.dll'\n";
    close $fh;
  }

  $ENV{PATH} = File::Spec->catdir($home, 'bin') . $Config{path_sep} . $ENV{PATH};

  chdir $root;
};

subtest 'normal ffi' => sub {
  plan skip_all => 'test requires FFI::Raw'
    unless eval q{ use FFI::Raw; 1 };
  plan tests => 2;

  chdir $home;

  alien_ok 'Alien::Xenolith', { config => {
    cflags => "-I%d/include",
    libs   => $Config{cc} !~ /cl(\.exe)?$/ ? "-L%d/lib -lfoo" : "-LIBPATH:%d/lib foo.lib",
    root   => $home,
  }};

  alien_ffi_ok 'fooish';

  chdir $root;
};

subtest 'no static ffi' => sub {
  plan skip_all => 'test requires FFI::Raw'
    unless eval q{ use FFI::Raw; 1 };
  plan skip_all => 'test is for gcc only' if $Config{cc} =~ /cl(\.exe)?$/;
  plan tests => 4;
  
  chdir $home;
  
  my $old = File::Spec->catfile('lib', 'libfoo.a');
  my $lib = File::Spec->catfile('lib', 'libfoo.dll.a');

  ok rename($old, $lib) && -r $lib && !-r $old, "rename $old => $lib";
  
  alien_ok 'Alien::Xenolith', { config => {
    cflags => "-I%d/include",
    libs   => "-L%d/lib -lfoo",
    root   => $home,
  }};

  alien_ffi_ok 'fooish';

  ok rename($lib, $old) && -r $old && !-r $lib, "rename $lib => $old";

  chdir $root;
};
