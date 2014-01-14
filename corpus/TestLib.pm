package TestLib;

use strict;
use warnings;
use base qw( Exporter );
use base 'Test::Builder::Module';
use File::Path qw( mkpath );
use File::Copy qw( cp );
use File::Spec;
use File::Basename qw( dirname );
use File::HomeDir;

our @EXPORT = qw( template_home_ok );

die "File::HomeDir::Test must already be loaded"
  unless $INC{'File/HomeDir/Test.pm'};

mkdir(File::Spec->catdir(File::HomeDir->my_home, '.ccache'))
  || die "unable to create ccache!";
  
sub _template_home_recurse
{
  my($template_root, @path) = @_;
  
  my @out;
    
  my $dh;
  opendir($dh, File::Spec->catdir($template_root, @path));
  my @fn = sort grep !/^\.\.?$/, readdir $dh;
  closedir $dh;
  
  foreach my $fn (@fn)
  {
    if(-d File::Spec->catdir($template_root, @path, $fn))
    {
      my $dir = File::Spec->catdir(File::HomeDir->my_home, @path, $fn);
      push @out, "mkdir $dir";
      mkdir($dir) || push @out, "error: $!";
      push @out, _template_home_recurse($template_root, @path, $fn);
    }
    else
    {
      my $src = File::Spec->catfile($template_root, @path, $fn);
      my $dst = File::Spec->catfile(File::HomeDir->my_home, @path, $fn);
      push @out, "cp $src $dst";
      cp($src, $dst) || push @out, "error: $!";
    }
  }
  
  @out;
}

sub template_home_ok ($)
{
  my($name, $msg) = @_;
  
  $msg ||= "applying fake home template $name";
  
  my $tb = __PACKAGE__->builder;
  
  my $template_root = File::Spec->catdir(dirname(__FILE__), $name );
  $tb->note("template_root = $template_root");
  
  my $ok = 1;
  my @out;
  
  if(-d $template_root)
  {
    @out = _template_home_recurse($template_root);  
  }
  else
  {
    $ok = 0;
  }
  
  $ok = 0 if grep /^error: /, @out;

  $tb->ok($ok, $msg);
  
  $tb->diag("no such dir: $template_root")
    unless -d $template_root;
  
  foreach my $out (@out)
  {
    if($out =~ /^error: /)
    {
      $tb->diag($out);
    }
    else
    {
      $tb->note($out);
    }
  }
}

1;
