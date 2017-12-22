require 'log4r'
require "vagrant-linode/client_wrapper"

module VagrantPlugins
  module Linode
    module Actions
      # This action connects to Linode, verifies credentials work, and
      # puts the Linode connection object into the `:linode_api` key
      # in the environment.
      class ConnectLinode
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_linode::action::connect_linode')
        end

        def call(env)
          # Get the configs
          config   = env[:machine].provider_config
          api_key  = config.api_key
          api_url  = config.api_url

          params = {
            apikey: api_key,
            endpoint: api_url
          }

          @logger.info('Connecting to Linode api_url...')

          linode = ClientWrapper.new(::LinodeAPI::Retryable.new(params), env[:ui])
          env[:linode_api] = linode

          @app.call(env)
        end
      end
    end
  end
end
