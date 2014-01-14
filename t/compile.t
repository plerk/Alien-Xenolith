use strict;
use warnings;
use File::HomeDir::Test;
use File::HomeDir;
use Test::More;
use FindBin ();
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'corpus');
use lib File::Spec->catdir(File::HomeDir->my_home, 'lib');
use TestLib;
use Capture::Tiny qw( capture_merged );
use Config;

plan skip_all => 'test requires ExtUtils::CChecker'
  unless eval q{ use ExtUtils::CChecker; 1 };
plan skip_all => 'test requires ExtUtils::CBuilder'
  unless eval q{ use ExtUtils::CBuilder; 1 };
plan skip_all => 'test requires c compiler'
  unless do {
    my $ok;
    note scalar capture_merged {
      $ok = ExtUtils::CBuilder->new->have_compiler;
    };
    $ok;
  };

my $home = File::HomeDir->my_home;

my $lib_name;

subtest prep => sub {
  plan tests => 1;
  template_home_ok 'compile';

  my $b = ExtUtils::CBuilder->new;

  my $base = File::Spec->catfile( $home, qw( lib auto Alien Foo E198DB4A-7C80-11E3-AEBD-2AD555543D6A ));
  
  note scalar capture_merged {
    my $obj = eval { $b->compile( source => File::Spec->catfile($base, qw( src foo.c )) ) };
    # TODO: portability $Config{ar} = lib on native M$
    
    mkdir(File::Spec->catdir($base, qw( lib )));

    my @cmd;

    if($^O eq 'MSWin32' && $Config{ar} =~ /^lib(\.exe)?$/)
    {
      $lib_name = 'foo.lib';
      my $fn = File::Spec->catfile($base, qw( lib foo.lib ));
      $fn =~ s{\\}{/}g;
      @cmd = ('lib', $obj, "/OUT:$fn");
      print "@cmd\n";
      system @cmd;
    }
    else
    {
      $lib_name = 'libfoo.a';
      @cmd = ('ar', 'rcs', File::Spec->catfile($base, qw( lib libfoo.a )), $obj);
      print "@cmd\n";
      system @cmd;
    
      @cmd = ('ranlib', File::Spec->catfile($base, qw( lib libfoo.a )));
      print "@cmd\n";
      system @cmd;
    };
  };
  
};

unless(defined $lib_name && -r File::Spec->catfile($home, qw( lib auto Alien Foo E198DB4A-7C80-11E3-AEBD-2AD555543D6A lib ), $lib_name))
{
  diag "unable to create libfoo.a (compiler may not be available, or I don't know how to compile)";
  done_testing;
  exit;
}

subtest 'object and fields' => sub {
  plan tests => 3;

  require Alien::Foo;
  my $alien = Alien::Foo->new;
  isa_ok $alien, 'Alien::Foo';
  
  ok $alien->cflags, "cflags = " . $alien->cflags;
  ok $alien->libs,   "libs   = " . $alien->libs;
  
};

subtest 'compile' => sub {
  plan tests => 3;
  
  my $ok;
  note scalar capture_merged {
    $ok = Alien::Foo->test_compiler;
  };
  
  ok $ok, 'test_compiler';
  
  my $out = scalar capture_merged {
    $ok = Alien::Foo->test_compiler(
      source => <<EOF,
#include <foo.h>
#include <stdio.h>
int
main(int argc, char *argv[])
{
  if(FOO != 42)
    return 1;
  if(fooish() != 42)
    return 1;
  printf("some output\\n");
  return 0;
}
EOF
    );
  };
  
  note $out;
  
  ok $ok, 'test_compiler with custom c source';
  like $out, qr{some output}, 'output matches';
};

subtest 'inline' => sub {
  plan skip_all => 'test requires Inline::C'
    unless eval q{ use Inline::C (); 1 };
  plan tests => 2;

  my %config = %{ Alien::Foo->Inline };
  foreach my $key (sort keys %config)
  {
    note "$key=$config{$key}";
  }
  
  use_ok 'Foo::Inline';
  
  is eval { Foo::Inline::all_good() }, 1, 'called all_good';
  diag $@ if $@;
};

subtest 'Module::Build' => sub {

  plan tests => 3;

  local $ENV{PERL5LIB} = join($Config{path_sep}, 
    File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'lib')),
    File::Spec->catdir(File::HomeDir->my_home, 'lib'),
    ($ENV{PERL5LIB} ? ($ENV{PERL5LIB}) : ()),
  );
  
  chdir(File::Spec->catdir(File::HomeDir->my_home, 'dev', 'Foo-XS-MB'));

  note scalar capture_merged {
    system $^X, 'Build.PL';
  };
  is $?, 0, "$^X Build.PL";
  
  note scalar capture_merged {
    system $^X, 'Build';
  };
  is $?, 0, 'Build';

  note scalar capture_merged {
    system $^X, 'Build', 'test';
  };
  is $?, 0, 'Build test';
  
  chdir(File::Spec->rootdir);
  
};

subtest 'ExtUtils::MakeMaker' => sub {

  plan skip_all => 'requires Module::Which'
    unless eval q{ use Module::Which; 1 };

  plan skip_all => 'requires ExtUtils::MakeMaker 6.30'
    unless eval q{ use ExtUtils::MakeMaker 6.30; 1 };

  plan skip_all => 'requires make'
    unless Module::Which::which($Config{make});

  plan tests => 3;

  local $ENV{PERL5LIB} = join($Config{path_sep}, 
    File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'lib')),
    File::Spec->catdir(File::HomeDir->my_home, 'lib'),
    ($ENV{PERL5LIB} ? ($ENV{PERL5LIB}) : ()),
  );

  chdir(File::Spec->catdir(File::HomeDir->my_home, 'dev', 'Foo-XS-MM'));

  note scalar capture_merged {
    system $^X, 'Makefile.PL';
  };
  is $?, 0, "$^X Makefile.PL";

  note scalar capture_merged {
    system $Config{make};
  };
  is $?, 0, "$Config{make}";
  
  note scalar capture_merged {
    system $Config{make}, 'test';
  };
  is $?, 0, "$Config{make} test";

  chdir(File::Spec->rootdir);
};

done_testing;
