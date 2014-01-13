# Alien::Xenolith [![Build Status](https://secure.travis-ci.org/plicease/Alien-Xenolith.png)](http://travis-ci.org/plicease/Alien-Xenolith)

Smooth interface for external libraries

# SYNOPSIS

# DESCRIPTION

# METHODS

## new

    my $alien = Alien::Foo->new(%args);

Create a new instance of an alien object.

### arguments

#### filter

    use Sort::Versions qw( versioncmp );
    my $alien = Alien::Foo->new( filter => sub { versioncmp($_[0]->version, '2.0.2') } );

Code reference that can be used to filter possible alien instances.
The alien instance will be passed in as the first argument and this
code reference will be expected to return 1 if it is okay.

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

## timestamp

    my $timestamp = $alien->timestamp;

Returns the timestamp for the given alien instance.

## version

    my $version = $alien->version;
    my $version = Alien::Foo->version;

Returns the version of the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

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
