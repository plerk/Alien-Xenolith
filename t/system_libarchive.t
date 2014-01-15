use strict;
use warnings;
use Test::More;
use Test::Xenolith;

plan skip_all => 'set TEST_XENOLITH_SYSTEM_LIBARCHIVE_LIBS and TEST_XENOLITH_SYSTEM_LIBARCHIVE_CFLAGS to run this test'
  unless $ENV{TEST_XENOLITH_SYSTEM_LIBARCHIVE_LIBS};

plan tests => 6;

my $cflags = $ENV{TEST_XENOLITH_SYSTEM_LIBARCHIVE_CFLAGS} || '';
my $libs   = $ENV{TEST_XENOLITH_SYSTEM_LIBARCHIVE_LIBS};

alien_ok 'Alien::Xenolith', [ config => { cflags => $cflags, libs => $libs } ];

alien_compile_ok;

my $out = alien_compile_ok {
  source => <<EOF,
#include <archive.h>
#include <archive_entry.h>
int
main(int argc, char *argv[])
{
  printf("here we are\\n");
  struct archive_entry *entry = archive_entry_new();
  printf("entry = %p\\n", entry);
  if(entry == NULL)
    return 1;
  archive_entry_free(entry);
  return 0;
}
EOF
}, 'custom compile';

like $out, qr{here we are}, 'output matches';

SKIP: {
  skip 'requires FFI::Raw', 2 unless eval { require FFI::Raw };
  alien_ffi_ok 'archive_entry_new';
  alien_ffi_ok 'archive_entry_free';
};
