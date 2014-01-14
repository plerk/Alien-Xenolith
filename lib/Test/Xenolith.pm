package Test::Xenolith;

use strict;
use warnings;
use base qw( Test::Builder::Module Exporter );
use Capture::Tiny qw( capture_merged );

our @EXPORT = qw( alien_ok alien_compile_ok alien_ffi_ok );

# ABSTRACT: Test interface for external libraries
# VERSION

=head1 SYNOPSIS

 use Test::More tests => 3;
 use Test::Xenolith;
 
 alien_ok 'Alien::Foo';
 alien_compile_ok;
 alien_ffi_ok 'foo';

=head1 FUNCTIONS

=head2 alien_ok

 alien_ok $class, $args, $message;

Passes if the give class can be required, instanciated
and is subclass of L<Alien::Xenolith>.

C<$args> are passed into the constructor.

=cut

my $alien;

sub alien_ok ($;$$)
{
  my($class, $args, $message) = @_;

  $message ||= "alien $class";
  $args    ||= [];
  $args = [ %$args ] if ref $args eq 'HASH';

  my $tb = __PACKAGE__->builder;
  
  my $ok = 0;
  
  if(eval qq{ require $class })
  {
    $alien = eval { $class->new(@$args) };
    if(defined $alien)
    {
      if(eval { $alien->isa("Alien::Xenolith") })
      {
        $ok = 1;
      }
      else
      {
        $tb->diag("is not an instance of Alien::Xenolith: $!");
        undef $alien;
      }
    }
    else
    {
      $tb->diag("unable to create instance of $class: $@");
    }
  }
  else
  {
    $tb->diag("unable to require $class: $@");
  }

  $tb->ok($ok, $message);
  
  $ok;
}

=head2 alien_compile_ok

 alien_compile_ok \%args, $message;

Does a simple compile test.  Must be run after L<alien_ok|Test::Xenolith#alien_ok>.

=cut

sub alien_compile_ok (;$$)
{
  my($args, $message) = @_;
  
  $args    ||= {};
  $message ||= "alien compiles";
  
  my $tb = __PACKAGE__->builder;
  
  my $ok = 0;
  my $out;
  
  if(defined $alien)
  {
    $out = capture_merged {
      $ok = $alien->test_compiler(%$args);
    };
    if($ok)
    {
      $tb->note($out);
    }
    else
    {
      $tb->diag($out);
    }
  }
  else
  {
    $tb->diag("no valid alien instance (may be due to alien_ok failure)");
  }
  
  $tb->ok($ok, $message);
  
  $out;
}

=head2 alien_ffi_ok

 alien_ffi_ok $symbol, $message;

Checks to see if the given symbol can be resolved using the given alien class.
Must be run after L<alien_ok|Test::Xenolith#alien_ok>.

=cut

sub alien_ffi_ok ($;$)
{
  my($symbol, $message) = @_;
  
  $message ||= "alien can resolve $symbol";
  
  my $tb = __PACKAGE__->builder;
  
  my $ok = 0;
  
  if(defined $alien)
  {
    if(eval { require FFI::Raw })
    {
      my $func = eval { FFI::Raw->new(scalar $alien->dlls, $symbol, FFI::Raw::void()) };
      if(defined $func)
      {
        $ok = 1;
      }
      else
      {
        $tb->diag("unable to resolve $symbol with " . scalar $alien->dlls . ": $@");
      }
    }
    else
    {
      $tb->diag("FFI::Raw did not load: $@");
    }
  }
  else
  {
    $tb->diag("no valid alien instance (may be due to alien_ok failure)");
  }
  
  $tb->ok($ok, $message);  
  
  $ok;
}

1;
