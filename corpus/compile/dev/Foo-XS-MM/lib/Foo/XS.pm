package Foo::XS;

use strict;
use warnings;

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Foo::XS', $VERSION);    

1;
