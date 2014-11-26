require 'vagrant-linode/helpers/client'

module VagrantPlugins
  module Linode
    module Actions
      class Reload
        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @logger = Log4r::Logger.new('vagrant::linode::reload')
        end

        def call(env)
          @client = env[:linode_api]
          # submit reboot linode request
          result = @client.linode.reboot(linodeid: @machine.id)

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_linode.info.reloading')
          wait_for_event(env, result['jobid'])
          @app.call(env)
        end
      end
    end
  end
end
