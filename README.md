# Alien::Xenolith [![Build Status](https://secure.travis-ci.org/plicease/Alien-Xenolith.png)](http://travis-ci.org/plicease/Alien-Xenolith)

Smooth interface for external libraries

# SYNOPSIS

As an alien developer:

    package Alien::Foo;
    
    use Alien::Xenolith -base;

(see [Alien::Xenolith::Recipe](https://metacpan.org/pod/Alien::Xenolith::Recipe) for information on writing the recipe
to go along with this)

As an alien user ([Module::Build](https://metacpan.org/pod/Module::Build)):

    use Module::Build;
    use Alien::Foo;
    Module::Build->new(
      ...
        configure_requires   => {
          "Module::Build" => "0.3601",
          "Alien::Foo"    => 0,
        },
      Alien::Foo->module_build,
    );

As an alien user ([ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)):

    use ExtUtils::MakeMaker 6.30;
    use Alien::Foo;
    WriteMakefile(
      ...
      CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => "6.30",
        "Alien::Foo"          => 0,
      },
      Alien::Foo->make_maker,
    );

As an alien user ([FFI::Raw](https://metacpan.org/pod/FFI::Raw)):

    use FFI::Raw;
    use Alien::Foo; 
    my $foo = FFI::Raw->new(
      scalar Alien::Foo->dlls, 'foo', FFI::Raw::int(),
    );
    $foo->();

As an alien user ([Inline::C](https://metacpan.org/pod/Inline::C)):

    use Alien::Foo;
    use Inline with => 'Alien::Foo';
    use Inline C => 'DATA';
    Inline->init;

# DESCRIPTION

Xenolith is intended as an alternative toolkit for creating
Alien distributions and modules.  It differentiates itself
from [Alien::Base](https://metacpan.org/pod/Alien::Base) mainly in that:

- supports upgrades

    With [Alien::Xenolith](https://metacpan.org/pod/Alien::Xenolith), the recipe for fetching, building
    and installing your alien library is separate from the Alien
    module itself, and also separate from your installer 
    (unlike [Alien::Base](https://metacpan.org/pod/Alien::Base) where the fetch, build and install
    are an integral part of [Alien::Base::ModuleBuild](https://metacpan.org/pod/Alien::Base::ModuleBuild)).

    This means that your XS module can request a more recent
    version of the library if it is available, or as an end user 
    you can install a more recent version on the command line.

- supports multiple platforms

    Out of the box, [Alien::Xenolith](https://metacpan.org/pod/Alien::Xenolith) is designed to create
    Alien distributions for Unix, Windows and cygwin.  Although
    with [Alien::Base](https://metacpan.org/pod/Alien::Base), this may be possible, in my experience
    it is not possible without significant effort and detailed
    subclassing. 

    (If your platform is not supported, please coordinate with me to fix
    that)

- supports multiple intents

    Designed from the get-go to work with XS, [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker),
    [Module::Build](https://metacpan.org/pod/Module::Build), [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla), [Inline](https://metacpan.org/pod/Inline), [FFI::Raw](https://metacpan.org/pod/FFI::Raw) and [FFI::Sweet](https://metacpan.org/pod/FFI::Sweet).

- static linking for XS

    Provides static libraries for when you are building a XS or [Inline](https://metacpan.org/pod/Inline)
    module.  This is important, because if you link your extension against
    a dynamic library (.so or .dll) then upgrading the Alien module may
    break existing XS modules.

    This also means that you don't have to pull in any Alien junk at 
    runtime for XS modules.

- dynamic linking for FFI

    Provides the full path to the dynamic library (.so or .dll), which can
    be provided directly to [FFI::Raw](https://metacpan.org/pod/FFI::Raw) or [FFI::Sweet](https://metacpan.org/pod/FFI::Sweet).  If possible it
    will do this without aid of a compiler.

# METHODS

For the usage examples, `Alien::Foo` is a class / module that
you've created and `$alien` is an instance of that class.
This is all that is required to declare that class:

    package Alien::Foo;
    use Alien::Xenolith -base;
    1;

## new

    my $alien = Alien::Foo->new(%args);

Create a new instance of an alien object.

### arguments

#### filter

    use Sort::Versions qw( versioncmp );
    my $alien = Alien::Foo->new(
      # only use libfoo with version 2.02 or better
      filter => sub { versioncmp($_[0]->version, '2.0.2') },
    );

Code reference that can be used to filter possible alien instances.
The alien instance will be passed in as the first argument and this
code reference will be expected to return 1 if it is okay.

#### cmp

    use Sort::Version qw( versioncmp );
    my $alien = Alien::Foo->new(
      # use the oldest version available
      cmp => sub { 0 - versioncmp($_[0]->version, $_[1]->version) },
    );

Specify a different comparison function for determining the best
alien instance to use.  If not specified, then [Alien::Xenolith](https://metacpan.org/pod/Alien::Xenolith)
will compare the version, and then the timestamp of each possible
instance.

#### config

    my @configs = Alien::Foo->get_configs;

    my $alien = Alien::Foo->new(
      # just use the first one off the list
      # even if it is old or stupid or something.
      config => $configs[0],
    );

Bypass the Xenolith search path and just specify the configuration
to use for the alien instance.

## cflags

    my $cflags = $alien->cflags;
    my $cflags = Alien::Foo->cflags;

Returns the cflags needed for compiling with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

## libs

    my $libs = $alien->libs;
    my $libs = Alien::Foo->libs;

Returns the libs needed for linking with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

## dlls

    my $dlls = $alien->dlls;
    my $dlls = Alien::Foo->dlls;

Returns the dlls for with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

## inline

    use Inline C => 'DATA' => $alien->inline;
    use Inline C => 'DATA' => Alien::Foo->inline;
    
    __DATA__
    __C__
    ...

alternately

    use Inline C => with 'Alien::Foo';
    use Inline C => 'DATA';
    
    __DATA__
    __C__
    ...

Returns the configuration that can be passed into [Inline](https://metacpan.org/pod/Inline)

## make\_maker

    my @args = Alien::Foo->make_maker;
    my @args = $alien->make_maker;

Return arguments which can be used by [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker).

## module\_build

    my @args = Alien::Foo->module_build;
    my @args = $alien->module_build;

Return arguments which can be used by [Module::Build](https://metacpan.org/pod/Module::Build).

## timestamp

    my $timestamp = $alien->timestamp;

Returns the timestamp for the given alien instance.

## version

    my $version = $alien->version;
    my $version = Alien::Foo->version;

Returns the version of the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

## test\_compiler

    my $ok = $alien->test_compiler( $c_source );
    my $ok = Alien::Foo->test_compiler( $c_source );

Test compiling and running with the alien instance.

## perl\_id

    my $perl_id = Alien::Xenolith->perl_id;

Identifier for the current Perl which can be used as a component of a directory path.

## search\_path

    my @list = Alien::Foo->search_path

List of directories to search for Xenolith configurations.

## install\_path

    my $dir = Alien::Foo->install_path;

Return the first directory in the search path that is writable.

## get\_configs

    my @configs = Alien::Foo->get_configs;

Return a list of hash refs that represent possible Xenolith configs.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
