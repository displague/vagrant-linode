require 'vagrant-linode/helpers/client'
require 'vagrant-linode/errors'

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
          ssh_key_id = env[:machine].config.ssh.private_key_path
          ssh_key_id = ssh_key_id[0] if ssh_key_id.is_a?(Array)

          if ssh_key_id
            pubkey = File.read(File.expand_path("#{ssh_key_id}.pub"))
          end

          if @machine.provider_config.root_pass
            root_pass = @machine.provider_config.root_pass
          else
            root_pass = Digest::SHA2.new.update(@machine.provider_config.api_key).to_s
          end

          if @machine.provider_config.distribution
            distributions = @client.avail.distributions
            distribution = distributions.find { |d| d.label.downcase.include? @machine.provider_config.distribution.downcase }
            raise( Errors::DistroMatch, distro: @machine.provider_config.distribution.to_s ) if distribution == nil
            distribution_id = distribution.distributionid || nil
          else
            distribution_id = @machine.provider_config.distributionid
          end

          if @machine.provider_config.datacenter
            datacenters = @client.avail.datacenters
            datacenter = datacenters.find { |d| d.abbr == @machine.provider_config.datacenter }
            datacenter_id = datacenter.datacenterid || nil # @todo throw if not found
          else
            datacenter_id = @machine.provider_config.datacenterid
          end

          if @machine.provider_config.plan
            plans = @client.avail.linodeplans
            plan = plans.find { |p| p.label.include? @machine.provider_config.plan }
            raise Errors::PlanID, plan: @machine.provider_config.plan if plan == nil
            plan_id = plan.planid || nil 
          else
            plan_id = @machine.provider_config.planid
          end

          ### Disk Images
          xvda_size, swap_size, disk_sanity = @machine.provider_config.xvda_size, @machine.provider_config.swap_size, true

          # Sanity checks for disk size
          if xvda_size != true
            disk_sanity = false if ( xvda_size.to_i + swap_size.to_i ) > ( plan['disk'].to_i * 1024 )
          end

          # throw if disk sizes are too large
          if xvda_size == true
            xvda_size = ( ( plan['disk'].to_i * 1024 ) - swap_size.to_i )
          elsif disk_sanity == false
            raise Errors::DiskSize, current: (xvda_size.to_i + swap_size.to_i), max: ( plan['disk'].to_i * 1024 )
          end

          env[:ui].info I18n.t('vagrant_linode.info.creating')

          # submit new linode request
          result = @client.linode.create(
            planid: plan_id,
            datacenterid: datacenter_id,
            paymentterm: @machine.provider_config.paymentterm || 1
          )
          env[:ui].info I18n.t('vagrant_linode.info.created', linodeid: result['linodeid'])

          # @client.linode.job.list(:linodeid => result['linodeid'], :pendingonly => 1)
          # assign the machine id for reference in other commands
          @machine.id = result['linodeid'].to_s

          if distribution_id
            swap = @client.linode.disk.create(
              linodeid: result['linodeid'],
              label: 'Vagrant swap',
              type: 'swap',
              size: swap_size
            )

            disk = @client.linode.disk.createfromdistribution(
              linodeid: result['linodeid'],
              distributionid: distribution_id,
              label: 'Vagrant Disk Distribution ' + distribution_id.to_s + ' Linode ' + result['linodeid'].to_s,
              type: 'ext4',
              size: xvda_size,
              rootsshkey: pubkey,
              rootpass: root_pass
            )
          elsif image_id
            disk = @client.linode.disk.createfromimage(
              linodeid: result['linodeid'],
              imageid: image_id,
              size: xvda_size,
              rootsshkey: pubkey,
              rootpass: root_pass
            )

            swap = @client.linode.disk.create(
              linodeid: result['linodeid'],
              label: 'Vagrant swap',
              type: 'swap',
              size: swap_size
            )
          end

	  # kernel id
	  kernel_id = @machine.provider_config.kernel_id

          config = @client.linode.config.create(
            linodeid: result['linodeid'],
            label: 'Vagrant Config',
            disklist: "#{disk['diskid']},#{swap['diskid']}",
            kernelid: kernel_id
          )

          # @todo: allow provisioning to set static configuration for networking
          if @machine.provider_config.private_networking
            private_network = @client.linode.ip.addprivate linodeid: result['linodeid']
          end

          label = @machine.provider_config.label
          label = label || @machine.name if @machine.name != 'default'
          label = label || get_server_name

          group = @machine.provider_config.group
          group = "" if @machine.provider_config.group == false

          result = @client.linode.update(
            linodeid: result['linodeid'],
            label: label,
            lpm_displaygroup: group
          )

          env[:ui].info I18n.t('vagrant_linode.info.booting', linodeid: result['linodeid'])

          bootjob = @client.linode.boot linodeid: result['linodeid']
          # sleep 1 until ! @client.linode.job.list(:linodeid => result['linodeid'], :jobid => bootjob['jobid'], :pendingonly => 1).length
          wait_for_event(env, bootjob['jobid'])

          # refresh linode state with provider and output ip address
          linode = Provider.linode(@machine, refresh: true)
          public_network = linode.network.find { |network| network['ispublic'] == 1 }
          env[:ui].info I18n.t('vagrant_linode.info.linode_ip', ip: public_network['ipaddress'])

          if private_network
            env[:ui].info I18n.t('vagrant_linode.info.linode_private_ip', ip: private_network['ipaddress'])
          end

          # wait for ssh to be ready
          switch_user = @machine.provider_config.setup?
          user = @machine.config.ssh.username
          if switch_user
            @machine.config.ssh.username = 'root'
            @machine.config.ssh.password = root_pass
          end

          retryable(tries: 25, sleep: 10) do # @todo bump tries when this is solid
            next if env[:interrupted]
            fail 'not ready' unless @machine.communicate.ready?
          end

          @machine.config.ssh.username = user

          @app.call(env)
        end

        # Both the recover and terminate are stolen almost verbatim from
        # the Vagrant AWS provider up action
        # def recover(env)
        #  print YAML::dump env['vagrant_error']
        #  return if env['vagrant.error'].is_a?(Vagrant::Errors::VagrantError)
        #  if @machine.state.id != -1
        #    terminate(env)
        #  end
        # end

        # generate a random name if server name is empty
        def get_server_name
          server_name = "vagrant_linode-#{rand.to_s.split('.')[1]}"
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
