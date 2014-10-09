module VagrantPlugins
  module Linode
    module Actions
      class ReadState
        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @logger = Log4r::Logger.new('vagrant_linode::action::read_state')
        end

        def call(env)
          env[:machine_state] = read_state(env[:linode_api], @machine)
          @logger.info "Machine state is '#{env[:machine_state]}'"
          @app.call(env)
        end

        def read_state(_linode, machine)
          return :not_created if machine.id.nil?
          server = Provider.linode(machine)
          return :not_created if server.nil?
	  status = server['status']
          return :not_created if status.nil?
          states = {
            ''  => :not_created,
            '-2' => :boot_failed,
            '-1' => :being_created,
            '0' => :brand_new, # brand new
            '1' => :active, # running
            '2' => :off, # powered off
            '3' => :shutting_down
          }
          states[status]
        end
      end
    end
  end
end
