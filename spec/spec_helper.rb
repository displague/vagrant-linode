if ENV['COVERAGE'] != 'false'
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
  SimpleCov.start

  # Normally classes are lazily loaded, so any class without a test
  # is missing from the report.  This ensures they show up so we can
  # see uncovered methods.
  require 'vagrant'
  Dir['lib/**/*.rb'].each do|file|
    require_string = file.match(/lib\/(.*)\.rb/)[1]
    require require_string
  end
end

require 'pry'
require 'rspec/its'

I18n.load_path << 'locales/en.yml'
I18n.reload!
