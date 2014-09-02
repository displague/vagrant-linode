require 'vagrant-linode/helpers/client'

module VagrantPlugins
  module Linode
    module Actions
      class PowerOn
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @logger = Log4r::Logger.new('vagrant::linode::power_on')
        end

        def call(env)
          # submit power on linode request
          result = @client.post("/v2/linodes/#{@machine.id}/actions", {
            :type => 'power_on'
          })

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_linode.info.powering_on') 
          @client.wait_for_event(env, result['action']['id'])

          # refresh linode state with provider
          Provider.linode(@machine, :refresh => true)

          @app.call(env)
        end
      end
    end
  end
end


