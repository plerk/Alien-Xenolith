package Alien::Xenolith;

use strict;
use warnings;

# ABSTRACT: Smooth interface for external libraries
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

For the usage examples, C<Alien::Foo> is a class / module that
you've created and C<$alien> is an instance of that class.
This is all that is required to declare that class:

 package Alien::Foo;
 use Alien::Xenolith -base;
 1;

=head2 new

 my $alien = Alien::Foo->new(%args);

Create a new instance of an alien object.

=head3 arguments

=head4 filter

 use Sort::Versions qw( versioncmp );
 my $alien = Alien::Foo->new(
   # only use libfoo with version 2.02 or better
   filter => sub { versioncmp($_[0]->version, '2.0.2') },
 );

Code reference that can be used to filter possible alien instances.
The alien instance will be passed in as the first argument and this
code reference will be expected to return 1 if it is okay.

=head4 cmp

 use Sort::Version qw( versioncmp );
 my $alien = Alien::Foo->new(
   # use the oldest version available
   cmp => sub { 0 - versioncmp($_[0]->version, $_[1]->version) },
 );

Specify a different comparison function for determining the best
alien instance to use.  If not specified, then L<Alien::Xenolith>
will compare the version, and then the timestamp of each possible
instance.

=head4 config

 my @configs = Alien::Foo->get_configs;

 my $alien = Alien::Foo->new(
   # just use the first one off the list
   # even if it is old or stupid or something.
   config => $configs[0],
 );

Bypass the Xenolith search path and just specify the configuration
to use for the alien instance.

=cut

sub new
{
  my($class, %args) = @_;

  return $class if ref $class;

  my $config;

  my @configs = $args{config} ? ($args{config}) : ($class->get_configs);

  require Sort::Versions
    unless $args{cmp};

  foreach my $try (@configs)
  {
    $try->{version} = 0 unless defined $try->{version};

    if($args{filter})
    {
      next unless $args{filter}->(bless $try, $class);
    }

    if(defined $config)
    {
      my $cmp;
      if($args{cmp})
      {
        $cmp = $args{cmp}->(bless($config, $class),bless($try, $class));
      }
      else
      {
        $cmp = Sort::Versions::versioncmp($config->{version}, $try->{version});
        $cmp = $config->{timestamp} <=> $try->{timestamp} if $cmp == 0;
      }
      $config = $try if $cmp < 0;
    }
    else
    {
      $config = $try;
    }
  }
  
  die "unable to find viable config for $class" unless defined $config;
  
  bless $config, $class;
}

=head2 cflags

 my $cflags = $alien->cflags;
 my $cflags = Alien::Foo->cflags;

Returns the cflags needed for compiling with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

=cut

sub _process
{
  my($self, $str) = @_;
  $str =~ s{%d}{$self->{root}}g;
  $str =~ s{%%}{%}g;
  $str;
}

sub cflags
{
  my $self = shift->new;
  $self->_process($self->{cflags});
}

=head2 libs

 my $libs = $alien->libs;
 my $libs = Alien::Foo->libs;

Returns the libs needed for linking with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

=cut

sub libs
{
  my $self = shift->new;
  $self->_process($self->{libs});
}

=head2 dlls

 my $dlls = $alien->dlls;
 my $dlls = Alien::Foo->dlls;

Returns the dlls for with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

=cut

sub dlls
{
  my $self = shift->new;
  my @dlls = map { $self->_process($_) } ref $self->{dlls} ? (@{ $self->{dlls} }) : ($self->{dlls});
  wantarray ? @dlls : $dlls[0];
}

=head2 inline

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

Returns the configuration that can be passed into L<Inline>

=cut

sub inline
{
  my $self = shift->new;
  return (
    CCFLAGSEX => $self->cflags,
    LIBS      => $self->libs
  );
}

=head2 timestamp

 my $timestamp = $alien->timestamp;

Returns the timestamp for the given alien instance.

=cut

sub timestamp { shift->{timestamp} }

=head2 version

 my $version = $alien->version;
 my $version = Alien::Foo->version;

Returns the version of the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

=cut

sub version { shift->new->{version} }


=head2 test_compiler

 my $ok = $alien->test_compiler( $c_source );
 my $ok = Alien::Foo->test_compiler( $c_source );

Test compiling and running with the alien instance.

=cut

sub test_compiler
{
  my $self = shift->new;
  my %args = @_;
  
  $args{quiet} = 0
    unless defined $args{quiet};
  
  require ExtUtils::CChecker;
  require Text::ParseWords;
  my $cc = ExtUtils::CChecker->new( quiet => $args{quiet} );
  $cc->push_extra_compiler_flags(Text::ParseWords::shellwords($self->cflags));
  $cc->push_extra_linker_flags(Text::ParseWords::shellwords($self->libs));
  
  $args{source} = 'int main(int argc, char *argv[]) { return 0; }'
    unless defined $args{source};
  
  $cc->try_compile_run(%args);
}

=head2 perl_id

 my $perl_id = Alien::Xenolith->perl_id;

Identifier for the current Perl which can be used as a component of a directory path.

=cut

do {
  my $perl_id;

  sub perl_id
  {
    unless(defined $perl_id)
    {
      my $ver = $];
      $ver =~ s/\./_/g;
      require Config;
      require File::Spec;
      $perl_id = File::Spec->catdir($ver, $Config::Config{archname})
    }
    $perl_id;
  }
};

=head2 search_path

 my @list = Alien::Foo->search_path

List of directories to search for Xenolith configurations.

=cut

sub search_path
{
  my($class) = @_;
  $class = ref $class if ref $class;

  my @search_path;

  require File::ShareDir;
  require File::Spec;
  
  my $dir = eval { File::ShareDir::module_dir($class) };
  if(defined $dir)
  {
    unless(File::Spec->file_name_is_absolute)
    {
      $dir = File::Spec->rel2abs($dir);
    }
    push @search_path, $dir;
  }

  my $name = $class;
  $name =~ s/::/-/g;

  if(defined $ENV{XENOLITH_PATH})
  {
    require Config;
    foreach my $dir (split $Config::Config{path_sep}, $ENV{XENOLITH_PATH})
    {
      push @search_path, File::Spec->catdir($dir, $name);
    }
  }

  require File::HomeDir;
  push @search_path, do {
    my $dir = File::Spec->catdir(
      File::HomeDir->my_dist_data('Alien-Xenolith', { create => 1 } ),
      $name,
    );
    $dir;
  };

  @search_path;
}

=head2 install_path

 my $dir = Alien::Foo->install_path;

Return the first directory in the search path that is writable.

=cut

sub install_path
{
  my($class) = @_;

  require File::Path;

  foreach my $dir ($class->search_path)
  {
    my $fn = File::Spec->catfile($dir, '_readonly');
    next if -e $fn;
    File::Path::mkpath($dir, 0, 0755);
    return $dir if -d $dir && -w $dir;
  }
  
  die "could not find a writable install path for $class";
}

=head2 get_configs

 my @configs = Alien::Foo->get_configs;

Return a list of hash refs that represent possible Xenolith configs.

=cut

sub get_configs
{
  my($class) = @_;

  my @config_list;

  require File::Spec;

  foreach my $dir1 ($class->search_path)
  {
    next unless -d $dir1;
    my @subdirs;
    do {
      my $dh;
      opendir $dh, $dir1;
      @subdirs = map { File::Spec->catdir($dir1, $_) } grep !/^\./, readdir $dh;
      closedir $dh;
    };
    foreach my $dir2 (@subdirs)
    {
      my $fn = File::Spec->catfile($dir2, 'config.pl');
      next unless -r $fn;
      my $config = eval { do $fn };
      next unless ref($config) eq 'HASH';
      require File::Basename;
      $config->{root} = File::Basename::dirname($fn);
      push @config_list, $config;
    }
  }
  
  @config_list;
}

sub import
{
  my $class = shift;
  
  return unless $class eq __PACKAGE__;
  
  foreach my $arg (@_)
  {
    if($arg eq '-base')
    {
      my $caller = caller;
      no strict 'refs';
      push @{"$caller\::ISA"}, __PACKAGE__;
      *{"$caller\::Inline"} = sub {
        my %h = $caller->inline;
        \%h;
      };
    }
    else
    {
      require 'Carp';
      Carp::croak("unknown option $arg");
    }
  };
}

1;
