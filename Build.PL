use Module::Build;

Module::Build->new (
  module_name    => 'Linux::Input',
  license        => 'perl',
  requires       => {
    'Class::Data::Inheritable' => 0,
    'IO::File'                 => 0,
    'IO::Select'               => 0,
  },
  build_requires => {
    'Test::More'               => 0,
  },
  script_files   => [
    'bin/evtest.pl'
  ],
)->create_build_script();

# vim:sw=2 sts=2 expandtab
# $Id$
