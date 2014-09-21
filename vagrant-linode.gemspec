# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-linode/version'

Gem::Specification.new do |gem|
  gem.name          = 'vagrant-linode'
  gem.version       = VagrantPlugins::Linode::VERSION
  gem.authors       = ['Marques Johansson', 'Jonathan Leal']
  gem.email         = ['marques@linode.com', 'jleal@linode.com']
  gem.description   = 'Enables Vagrant to manage Linode linodes'
  gem.summary       = gem.description

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'linode'
  gem.add_dependency 'json'
  gem.add_dependency 'log4r'
end
