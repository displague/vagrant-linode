require 'bundler/gem_helper'

namespace :gem do
  Bundler::GemHelper.install_tasks
end

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
