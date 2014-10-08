require 'vagrant-linode/helpers/client'

module VagrantPlugins
  module Linode
    module Actions
      class Rebuild
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = env[:linode_api]
          @logger = Log4r::Logger.new('vagrant::linode::rebuild')
        end

        def call(env)
          # @todo find a convenient way to send provider_config back to the create action, reusing the diskid or configid
          fail 'not implemented'
          # look up image id
          image_id = @client
            .request('/v2/images')
            .find_id(:images, name: @machine.provider_config.image)

          # submit rebuild request
          result = @client.post("/v2/linodes/#{@machine.id}/actions", type: 'rebuild',
                                                                      image: image_id)

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_linode.info.rebuilding')
          wait_for_event(env, result['jobid'])

          # refresh linode state with provider
          Provider.linode(@machine, refresh: true)

          # wait for ssh to be ready
          switch_user = @machine.provider_config.setup?
          user = @machine.config.ssh.username
          @machine.config.ssh.username = 'root' if switch_user

          retryable(tries: 120, sleep: 10) do
            next if env[:interrupted]
            fail 'not ready' unless @machine.communicate.ready?
          end

          @machine.config.ssh.username = user

          @app.call(env)
        end
      end
    end
  end
end
