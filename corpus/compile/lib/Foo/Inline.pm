package Foo::Inline;

use strict;
use warnings;
use Alien::Foo;
use Inline with => 'Alien::Foo';
use Inline C => 'DATA', 
           DIRECTORY => do {
             require File::Spec;
             require File::HomeDir;
             my $dir = File::Spec->catdir(File::HomeDir->my_home, '_Inline');
             mkdir $dir;
             $dir;
           };

Inline->init;

1;

__DATA__
__C__

#include <foo.h>

int all_good() {
  if(FOO != 42)
    return 0;
  if(fooish() != 42)
    return 0;
  return 1;
}
