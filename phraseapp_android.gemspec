# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'phraseapp_android/version'

Gem::Specification.new do |spec|
  spec.name          = 'phraseapp_android'
  spec.version       = PhraseappAndroid::VERSION
  spec.authors       = ['Sergey Glukhov (serggl)']
  spec.email         = ['sergey.glukhov@gmail.com']
  spec.license       = 'MIT'

  spec.summary       = 'Manage Android localization data with PhraseApp'
  spec.description   = 'This gem is intended to make managing PhraseApp translations in Android projects much easier.'
  spec.homepage      = "https://github.com/anjlab/phraseapp_android"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   << 'phrase_app_translations'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'phraseapp-ruby', '~> 1.2'
  spec.add_runtime_dependency 'nokogiri', '~> 1.6'
  spec.add_runtime_dependency 'colorize', '~> 0.7'
end
