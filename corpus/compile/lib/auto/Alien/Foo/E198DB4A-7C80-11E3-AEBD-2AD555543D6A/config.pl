{
  cflags    => "-I%d/include -DFOO=42",
  # Question: can/should this transformation happen automatically in Alien::Xenomorph
  libs      => ($^O ne 'MSWin32' || $Config::Config{cc} !~ /cl(\.exe)?$/ ? "-L%d/lib -lfoo" : "-LIBPATH:%d/lib foo.lib"),
  version   => '1.00',
  timestamp => 123456789,
}
