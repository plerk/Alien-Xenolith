package Alien::Xenolith;

use strict;
use warnings;
use File::ShareDir ();
use File::Path     ();
use File::HomeDir;
use Config;
use File::Spec;

# ABSTRACT: Smooth interface for external libraries
# VERSION

=head1 METHODS

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

1;
