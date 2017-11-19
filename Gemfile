source 'https://rubygems.org'
ruby '~> 2.2.0'

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant'
  gem 'coveralls', require: false
  gem 'pry'
end

group :plugins do
  gemspec
end
