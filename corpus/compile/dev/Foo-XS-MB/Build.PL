use Module::Build;
use Alien::Foo;
Module::Build->new(
  configure_requires   => {
    "Module::Build" => "0.3601",
    "Alien::Foo"    => 0,
  },
  dist_abstract        => "Perl bindings to Foo via XS",
  dist_author => [
    "Graham Ollis <plicease\@cpan.org>"
  ],
  dist_name            => "Foo-XS",
  dist_version         => '1.00',
  license              => "perl",
  module_name          => "Foo::XS",
  extra_compiler_flags => Alien::Foo->cflags,
  extra_linker_flags   => Alien::Foo->libs,
)->create_build_script;
