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
use File::Copy qw( cp );
use File::Basename qw( basename );
use Data::Dumper;
use Config;
use Text::ParseWords qw( shellwords );
use Test::Xenolith;

plan skip_all => 'test requires FFI::Raw'
  unless eval q{ use FFI::Raw; 1 };
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

subtest prep => sub {
  plan tests => 1;
  template_home_ok 'ffi';

  my $b = ExtUtils::CBuilder->new;

  my $base = File::Spec->catfile( $home, qw( lib auto Alien Foo E198DB4A-7C80-11E3-AEBD-2AD555543D6A ));
  
  eval {
    my $obj = capture_note { $b->compile( source => File::Spec->catfile($base, qw( src foo.c )) ) };
    my $lib;
      
    if($^O eq 'MSWin32')
    {
      $lib = File::Spec->catfile($base, qw( src foo.dll ));
      if($Config{cc} =~ /cl(\.exe)?$/)
      {
        my $def = File::Spec->catfile($base, qw( src foo.def ));
        $def =~ s{\\}{/}g;
        $lib =~ s{\\}{/}g;
        run $Config{cc}, $obj, $def, "/link", "/dll", "/out:$lib";
      }
      else
      {
        my $lddlflags = $Config{lddlflags};
        $lddlflags =~ s{\\}{/}g;
        run $Config{cc}, shellwords($lddlflags), -o => $lib, "-Wl,--export-all-symbols", $obj;
      }
      die if $?;
    }
    else
    {
      $lib = capture_note { $b->link( objects => $obj ) };
    }
    
    mkdir(File::Spec->catdir($base, qw( dll )));
    
    my $name = basename $lib;
    
    capture_note {
    
      my $dst = File::Spec->catfile($base, 'dll', $name);
      print "cp $lib => $dst\n";
      cp($lib, $dst) || die "unable to copy $!";

      local $Data::Dumper::Terse = 1;
      my $fh;
      my $fn = File::Spec->catfile($base, qw( config.pl ));
      open($fh, '>', $fn) || die "unable to create $fn $!";
      print $fh Dumper({
        cflags    => '',
        libs      => '',
        version   => '1.00',
        timestamp => time,
        dlls      => [ "%d/dll/$name" ],
      });
      close $fh;
      
    };
  };
};

unless(-r File::Spec->catfile($home, qw( lib auto Alien Foo E198DB4A-7C80-11E3-AEBD-2AD555543D6A config.pl )))
{
  diag "unable to create config.pl (compiler may not be available, or I don't know how to compile dynamic libraries with it)";
  done_testing;
  exit;
}

subtest 'can load class' => sub {
  plan tests => 3;
  use_ok 'Alien::Foo';
  my $alien = Alien::Foo->new;
  isa_ok $alien, 'Alien::Foo';
  my $dll = $alien->dlls;
  ok -e $dll, "dll = $dll";
};

subtest 'use ffi raw' => sub {
  plan tests => 2;
  my $fooish = eval {
    FFI::Raw->new(
      scalar Alien::Foo->dlls, 'fooish', FFI::Raw::int(),
    );
  };
  diag $@ if $@;
  ok defined $fooish, "found fooish()";
  is $fooish->call(), 42, 'fooish() returns 42';
};

subtest 'Test::Xenolith' => sub {
  plan tests => 2;
  
  alien_ok 'Alien::Foo';
  alien_ffi_ok 'fooish';
};

subtest 'use ffi sweet' => sub {
  plan skip_all => 'TODO: write integration + test for FFI::Sweet';
};

done_testing;
