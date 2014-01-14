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
plan skip_all => 'TODO: test doesn\'t work with MS Visual C++'
  if $Config{ar} =~ /^lib(\.exe)?$/;

my $home = File::HomeDir->my_home;

subtest prep => sub {
  plan tests => 1;
  template_home_ok 'compile';

  my $b = ExtUtils::CBuilder->new;

  my $base = File::Spec->catfile( $home, qw( lib auto Alien Foo E198DB4A-7C80-11E3-AEBD-2AD555543D6A ));
  
  note scalar capture_merged {
    my $obj = eval { $b->compile( source => File::Spec->catfile($base, qw( src foo.c )) ) };
    # TODO: portability $Config{ar} = lib on native M$
    
    mkdir(File::Spec->catdir($base, qw( lib )));
    
    my @cmd = ('ar', 'rcs', File::Spec->catfile($base, qw( lib libfoo.a )), $obj);
    print "@cmd\n";
    system @cmd;
    
    @cmd = ('ranlib', File::Spec->catfile($base, qw( lib libfoo.a )));
    print "@cmd\n";
    system @cmd;
  };
  
};

unless(-r File::Spec->catfile($home, qw( lib auto Alien Foo E198DB4A-7C80-11E3-AEBD-2AD555543D6A lib libfoo.a )))
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

done_testing;
