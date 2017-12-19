require 'vagrant-linode/helpers/client'
require 'vagrant-linode/helpers/waiter'
require 'vagrant-linode/errors'
require 'vagrant-linode/services/volume_manager'

module VagrantPlugins
  module Linode
    module Actions
      class Create
        include Vagrant::Util::Retryable
        include VagrantPlugins::Linode::Helpers::Waiter

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @logger = Log4r::Logger.new('vagrant::linode::create')
        end

        def call(env)
          @client = env[:linode_api]
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

          if @machine.provider_config.stackscript
            stackscripts = @client.stackscript.list + @client.avail.stackscripts
            stackscript = stackscripts.find { |s| s.label.downcase == @machine.provider_config.stackscript.to_s.downcase }
            fail(Errors::StackscriptMatch, stackscript: @machine.provider_config.stackscript.to_s) if stackscript.nil?
            stackscript_id = stackscript.stackscriptid || nil
          else
            stackscript_id = @machine.provider_config.stackscriptid
          end

          stackscript_udf_responses = @machine.provider_config.stackscript_udf_responses

          if stackscript_udf_responses and !stackscript_udf_responses.is_a?(Hash)
            fail(Errors::StackscriptUDFFormat, format: stackscript_udf_responses.class.to_s)
          else
            stackscript_udf_responses = @machine.provider_config.stackscript_udf_responses or {}
          end

          if @machine.provider_config.distribution
            distributions = @client.avail.distributions
            distribution = distributions.find { |d| d.label.downcase.include? @machine.provider_config.distribution.downcase }
            fail(Errors::DistroMatch, distro: @machine.provider_config.distribution.to_s) if distribution.nil?
            distribution_id = distribution.distributionid || nil
          else
            distribution_id = @machine.provider_config.distributionid
          end

          if @machine.provider_config.imageid
            distribution_id = nil
            images = @client.image.list
            image = images.find { |i| i.imageid == @machine.provider_config.imageid }
            fail Errors::ImageMatch, image: @machine.provider_config.imageid.to_s  if image.nil?
            image_id = image.imageid || nil
          elsif @machine.provider_config.image
            distribution_id = nil
            images = @client.image.list
            image = images.find { |i| i.label.downcase.include? @machine.provider_config.image.downcase }
            fail Errors::ImageMatch, image: @machine.provider_config.image.to_s  if image.nil?
            image_id = image.imageid || nil
          end

          if @machine.provider_config.kernel
            kernels = @client.avail.kernels(isxen: nil, iskvm: 1)
            kernel = kernels.find { |k| k.label.downcase.include? @machine.provider_config.kernel.downcase }
            raise( Errors::KernelMatch, kernel: @machine.provider_config.kernel.to_s ) if kernel == nil
            kernel_id = kernel.kernelid || nil
          else
            kernel_id = @machine.provider_config.kernelid
          end

          if @machine.provider_config.datacenter
            datacenters = @client.avail.datacenters
            datacenter = datacenters.find { |d| d.abbr == @machine.provider_config.datacenter }
            fail Errors::DatacenterMatch, datacenter: @machine.provider_config.datacenter if datacenter.nil?
            datacenter_id = datacenter.datacenterid
          else
            datacenters = @client.avail.datacenters
            datacenter = datacenters.find { |d| d.datacenterid == @machine.provider_config.datacenterid }
            fail Errors::DatacenterMatch, datacenter: @machine.provider_config.datacenter if datacenter.nil?
            datacenter_id = datacenter.datacenterid
          end

          if @machine.provider_config.plan
            plans = @client.avail.linodeplans
            plan = plans.find { |p| p.label.include? @machine.provider_config.plan }
            fail Errors::PlanID, plan: @machine.provider_config.plan if plan.nil?
            plan_id = plan.planid
          else
            plans = @client.avail.linodeplans
            plan = plans.find { |p| p.planid.to_i == @machine.provider_config.planid.to_i }
            fail Errors::PlanID, plan: @machine.provider_config.planid if plan.nil?
            plan_id = @machine.provider_config.planid
          end

          ### Disk Images
          disk_size = plan['disk'].to_i * 1024
          xvda_size, swap_size, xvdc_size = @machine.provider_config.xvda_size, @machine.provider_config.swap_size, @machine.provider_config.xvdc_size

          swap_size = swap_size.to_i
          xvda_size = xvda_size == true ? disk_size - swap_size : xvda_size.to_i
          xvdc_size = (xvdc_size.is_a?(Vagrant::Config::V2::DummyConfig) or xvdc_size == true) ? (disk_size - swap_size - xvda_size).abs : xvdc_size.to_i

          if ( xvda_size + swap_size + xvdc_size) > disk_size
            fail Errors::DiskSize, current: (xvda_size + swap_size + xvdc_size), max: disk_size
          end

          env[:ui].info I18n.t('vagrant_linode.info.creating')

          # submit new linode request
          result = @client.linode.create(
            planid: plan_id,
            datacenterid: datacenter_id,
            paymentterm: @machine.provider_config.paymentterm || 1
          )
          @machine.id = result['linodeid'].to_s
          env[:ui].info I18n.t('vagrant_linode.info.created', linodeid: @machine.id, label: (@machine.provider_config.label or "linode#{@machine.id}"))

          # @client.linode.job.list(:linodeid => @machine.id, :pendingonly => 1)
          # assign the machine id for reference in other commands

          disklist = []

          if stackscript_id
            disk = @client.linode.disk.createfromstackscript(
              linodeid: @machine.id,
              stackscriptid: stackscript_id,
              stackscriptudfresponses: JSON.dump(stackscript_udf_responses),
              distributionid: distribution_id,
              label: 'Vagrant Disk Distribution ' + distribution_id.to_s + ' Linode ' + @machine.id,
              type: 'ext4',
              size: xvda_size,
              rootsshkey: pubkey,
              rootpass: root_pass
            )
            disklist.push(disk['diskid'])
          elsif distribution_id
            disk = @client.linode.disk.createfromdistribution(
              linodeid: @machine.id,
              distributionid: distribution_id,
              label: 'Vagrant Disk Distribution ' + distribution_id.to_s + ' Linode ' + @machine.id,
              type: 'ext4',
              size: xvda_size,
              rootsshkey: pubkey,
              rootpass: root_pass
            )
            disklist.push(disk['diskid'])
          elsif image_id
            disk = @client.linode.disk.createfromimage(
              linodeid: @machine.id,
              imageid: image_id,
              label: 'Vagrant Disk Image (' + image_id.to_s + ') for ' + @machine.id,
              size: xvda_size,
              rootsshkey: pubkey,
              rootpass: root_pass
            )
            disklist.push(disk['diskid'])
          else
            disklist.push('')
          end

          if swap_size > 0
            swap = @client.linode.disk.create(
              linodeid: @machine.id,
              label: 'Vagrant swap',
              type: 'swap',
              size: swap_size
            )
            disklist.push(swap['diskid'])
          else
            disklist.push('')
          end

          if xvdc_size > 0
            xvdc_type = @machine.provider_config.xvdc_type.is_a?(Vagrant::Config::V2::DummyConfig) ? "raw" : @machine.provider_config.xvdc_type
            xvdc = @client.linode.disk.create(
              linodeid: @machine.id,
              label: 'Vagrant Leftover Disk Linode ' + @machine.id,
              type: xvdc_type,
              size: xvdc_size,
            )
            disklist.push(xvdc['diskid'])
          else
            disklist.push('')
          end

          config = @client.linode.config.create(
            linodeid: @machine.id,
            label: 'Vagrant Config',
            disklist: disklist.join(','),
            kernelid: kernel_id
          )

          # @todo: allow provisioning to set static configuration for networking
          if @machine.provider_config.private_networking
            private_network = @client.linode.ip.addprivate linodeid: @machine.id
          end

          label = @machine.provider_config.label
          label = label || @machine.name if @machine.name != 'default'
          label = label || get_server_name

          group = @machine.provider_config.group
          group = "" if @machine.provider_config.group == false

          Services::VolumeManager.new(@machine, @client.volume, env[:ui]).perform

          result = @client.linode.update(
            linodeid: @machine.id,
            label: label,
            lpm_displaygroup: group
          )

          env[:ui].info I18n.t('vagrant_linode.info.booting', linodeid: @machine.id)

          bootjob = @client.linode.boot linodeid: @machine.id
          # sleep 1 until ! @client.linode.job.list(:linodeid => @machine.id, :jobid => bootjob['jobid'], :pendingonly => 1).length
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
          "vagrant_linode-#{rand.to_s.split('.')[1]}"
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
