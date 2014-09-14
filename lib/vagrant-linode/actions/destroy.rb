require 'vagrant-linode/helpers/client'

module VagrantPlugins
  module Linode
    module Actions
      class Destroy
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @logger = Log4r::Logger.new('vagrant::linode::destroy')
        end

        def call(env)
          # submit destroy linode request
          @client.linode.delete(linodeid: @machine.id, skipchecks: true)

          env[:ui].info I18n.t('vagrant_linode.info.destroying')

          # set the machine id to nil to cleanup local vagrant state
          @machine.id = nil

          @app.call(env)
        end
      end
    end
  end
end
