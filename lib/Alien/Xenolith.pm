package Alien::Xenolith;

use strict;
use warnings;
use File::ShareDir ();
use File::Path     ();
use File::HomeDir;
use Config;
use File::Spec;
use Sort::Versions ();

# ABSTRACT: Smooth interface for external libraries
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

 my $alien = Alien::Foo->new(%args);

Create a new instance of an alien object.

=head3 arguments

=head4 filter

 use Sort::Versions qw( versioncmp );
 my $alien = Alien::Foo->new( filter => sub { versioncmp($_[0]->version, '2.0.2') } );

Code reference that can be used to filter possible alien instances.
The alien instance will be passed in as the first argument and this
code reference will be expected to return 1 if it is okay.

=cut

sub new
{
  my($class, %args) = @_;

  return $class if ref $class;

  my $config;

  foreach my $try ($class->get_configs)
  {
    $try->{version} = 0 unless defined $try->{version};

    if($args{filter})
    {
      next unless $args{filter}->(bless $try, $class);
    }

    if(defined $config)
    {
      my $cmp = Sort::Versions::versioncmp($config->{version}, $try->{version});
      $cmp = $config->{timestamp} <=> $try->{timestamp} if $cmp == 0;
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

sub cflags { shift->new->{cflags} }

=head2 libs

 my $libs = $alien->libs;
 my $libs = Alien::Foo->libs;

Returns the libs needed for linking with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

=cut

sub libs { shift->new->{libs} }

=head2 dlls

 my $dlls = $alien->dlls;
 my $dlls = Alien::Foo->dlls;

Returns the dlls for with the given alien instance.  Can be called as a class method,
in which case the latest version will be used.

=cut

sub dlls { shift->new->{dlls} }

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
      $perl_id = File::Spec->catdir($ver, $Config{archname})
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
    foreach my $dir (split $Config{path_sep}, $ENV{XENOLITH_PATH})
    {
      push @search_path, File::Spec->catdir($dir, $name);
    }
  }

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

  foreach my $dir ($class->search_path)
  {    
    File::Path::mkpath($dir, 0, 0755);
    # TODO: Cygwin may not get this right...
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
      push @config_list, $config;
    }
  }
  
  @config_list;
}

1;
