require 'log4r'

module VagrantPlugins
  module Linode
    module Actions
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_linode::action::read_ssh_info')
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:linode_api], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(_linode, machine)
          return nil if machine.id.nil?
          server = Provider.linode(machine, refresh: true)

          return nil if machine.state.id != :active # @todo this seems redundant to the next line.
          if server.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          public_network = server.network.find { |network| network['ispublic'] == 1 }

          {
            host: public_network['ipaddress'],
            port: '22',
            username: 'root',
            private_key_path: machine.config.ssh.private_key_path
          }
        end
      end
    end
  end
end
