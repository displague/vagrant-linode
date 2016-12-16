# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-linode/version'

Gem::Specification.new do |gem|
  gem.name          = 'vagrant-linode'
  gem.version       = VagrantPlugins::Linode::VERSION
  gem.licenses      = ['MIT']
  gem.authors       = ['Marques Johansson', 'Jonathan Leal']
  gem.email         = ['marques@linode.com', 'jleal@linode.com']
  gem.description   = 'Enables Vagrant to manage Linode linodes'
  gem.homepage      = 'https://www.github.com/displague/vagrant-linode'
  gem.summary       = gem.description

  gem.add_runtime_dependency 'linodeapi', '~> 1.0'
  gem.add_runtime_dependency 'log4r', '~> 1.1'

  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rspec', '~> 3.5'
  gem.add_development_dependency 'aruba', '~> 0.14'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
