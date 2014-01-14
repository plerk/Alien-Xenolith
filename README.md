# Alien::Xenolith [![Build Status](https://secure.travis-ci.org/plicease/Alien-Xenolith.png)](http://travis-ci.org/plicease/Alien-Xenolith)

Smooth interface for external libraries

# SYNOPSIS

# DESCRIPTION

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
