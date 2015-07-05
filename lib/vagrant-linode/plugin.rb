begin
  require 'vagrant'
rescue LoadError
  raise 'The Linode provider must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.1.0'
  fail 'Linode provider is only compatible with Vagrant 1.1+'
end

module VagrantPlugins
  module Linode
    class Plugin < Vagrant.plugin('2')
      name 'Linode'
      description <<-DESC
        This plugin installs a provider that allows Vagrant to manage
        machines using Linode's API.
      DESC

      config(:linode, :provider) do
        require_relative 'config'
        Config
      end

      provider(:linode, parallel: true) do
        Linode.init_i18n
        Linode.init_logging

        require_relative 'provider'
        Provider
      end

      command(:linode) do
        require_relative 'commands/root'
        Commands::Root
      end

      command(:rebuild) do
        require_relative 'commands/rebuild'
        Commands::Rebuild
      end
    end
  end
end
