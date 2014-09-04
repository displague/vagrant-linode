require 'vagrant-linode/helpers/client'

module VagrantPlugins
  module Linode
    module Actions
      class Create
        include Helpers::Client
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @logger = Log4r::Logger.new('vagrant::linode::create')
        end

        def call(env)
          ssh_key_id = [env[:ssh_key_id]]

          image_id = @client
            .request('/v2/images')
            .find_id(:images, :name => @machine.provider_config.image)

          # submit new linode request
          result = @client.linode.create(
            :planid => @machine.provider_config.size || @client.avail.linodeplans.first['planid'],
            :datacenterid => @machine.provider_config.region,
            :paymentterm => @machine.provider_config.billing || 1
          );

          sleep 1 until ! @client.linode.job.list(:linodeid => result['linodeid'], :jobid => result['jobid']).length
          
          disk = @client.linode.disk.createfromdistribution(
            :linodeid => result.linodeid,
            :label => 'disk',
            :type => 'ext4',
            :size => 1024,
            :rootSSHKey => ssh_key_id
          )

          config = @client.linode.config.create(
            :linodeid => result['linodeid'],
            :label => 'Config',
            :disklist => "#{disk['diskid']}"
          )

          result = @client.linode.update(
            :linodeid => result.linodeid,
            :label => @machine.config.vm.hostname || @machine.name
            :ssh_keys => ssh_key_id,
            :private_networking => @machine.provider_config.private_networking,
            :backups => @machine.provider_config.backups_enabled,
            :ipv6 => @machine.provider_config.ipv6
          )

          # wait for request to complete
          env[:ui].info I18n.t('vagrant_linode.info.creating') 
          @client.wait_for_event(env, result['links']['actions'].first['id'])

          # assign the machine id for reference in other commands
          @machine.id = result['linode']['id'].to_s

          # refresh linode state with provider and output ip address
          linode = Provider.linode(@machine, :refresh => true)
          public_network = linode['networks']['v4'].find { |network| network['type'] == 'public' }
          private_network = linode['networks']['v4'].find { |network| network['type'] == 'private' }
          env[:ui].info I18n.t('vagrant_linode.info.linode_ip', {
            :ip => public_network['ip_address']
          })
          if private_network
            env[:ui].info I18n.t('vagrant_linode.info.linode_private_ip', {
              :ip => private_network['ip_address']
            })
          end

          # wait for ssh to be ready
          switch_user = @machine.provider_config.setup?
          user = @machine.config.ssh.username
          @machine.config.ssh.username = 'root' if switch_user

          retryable(:tries => 120, :sleep => 10) do
            next if env[:interrupted]
            raise 'not ready' if !@machine.communicate.ready?
          end

          @machine.config.ssh.username = user

          @app.call(env)
        end

        # Both the recover and terminate are stolen almost verbatim from
        # the Vagrant AWS provider up action
        def recover(env)
          return if env['vagrant.error'].is_a?(Vagrant::Errors::VagrantError)

          if @machine.state.id != :not_created
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Actions.destroy, destroy_env)
        end
      end
    end
  end
end
