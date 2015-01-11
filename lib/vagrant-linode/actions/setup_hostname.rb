# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
	module Linode
		module Actions
			class SetupHostname

				def initialize(app, env)
					@app 	 = app
					@machine = env[:machine]
					@logger	 = Log4r::Logger.new('vagrant::linode::setup_hostname')
				end

				def call(env)
					# Check if setup is enabled
					return @app.call(env) unless @machine.provider_config.setup?

					# Set Hostname
					if @machine.config.vm.hostname
						env[:ui].info I18n.t('vagrant_linode.info.modifying_host', name: @machine.config.vm.hostname)

						@machine.communicate.execute(<<-BASH)
							sudo echo -n #{@machine.config.vm.hostname} > /etc/hostname;
							sudo hostname -F /etc/hostname
						BASH
					end
				end
			end
		end
	end
end