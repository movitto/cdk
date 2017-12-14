lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cdk'

LIB_FILES = Dir.glob("lib/**/*.rb")

SUMMARY     = 'A Ruby version of Thomas Dickey version of the curses development kit'

DESCRIPTION = 'This is a pure ruby port of the CDK ncurses widget toolkit.'

Gem::Specification.new do |spec|
  spec.name          = 'cdk'
  spec.version       = CDK.Version
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Mo Morsi']
  spec.email         = ['mo@morsi.org']
  spec.has_rdoc      = false

  # Originally from: https://github.com/masterzora/tawny-cdk
  # But inactive for several years: https://github.com/masterzora/tawny-cdk/pulls
  # With an ancient (and currently incompatible) PR to add gemspec:
  # https://github.com/masterzora/tawny-cdk/pull/3
  #
  # So I'm taking it over!!! mwhahaha!!!

  spec.homepage      = 'http://github.com/movitto/cdk'
  spec.summary       = SUMMARY
  spec.description   = DESCRIPTION
  spec.license       = "BSD-3-Clause"

  spec.require_paths = ['lib']
  spec.files         = LIB_FILES

  spec.add_dependency 'ncursesw', '~> 1.4' # only tested against 1.4.10, milage
                                           # may vary with other versions!
end
