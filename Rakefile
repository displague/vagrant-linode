require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'

# Immediately sync all stdout so that tools like buildbot can
# immediately load in the output.
$stdout.sync = true
$stderr.sync = true

# Change to the directory of this file.
Dir.chdir(File.expand_path('../', __FILE__))

# This installs the tasks that help with gem creation and
# publishing.
namespace :gem do
  Bundler::GemHelper.install_tasks
end

# Install the `spec` task so that we can run tests.
RSpec::Core::RakeTask.new

# Default task is to run the unit tests
task default: 'spec'

# require 'bundler/gem_helper'

task :test do
  result = sh 'bash test/test.sh'

  if result
    puts 'Success!'
  else
    puts 'Failure!'
    exit 1
  end
end

def env
  %w(LINODE_CLIENT_ID LINODE_API_KEY VAGRANT_LOG).reduce('') do |acc, key|
    acc += "#{key}=#{ENV[key] || 'error'} "
  end
end
