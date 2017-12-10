module VagrantPlugins
  module Linode
    module Actions
      class ListVolumes
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          api = env[:linode_api]
          logger = env[:ui]
          machine = env[:machine]

          remote_volumes = api.volume.list
          volume_definitions = machine.provider_config.volumes

          volume_definitions.each do |volume|
            volume_label = "#{machine.name}_#{volume[:label]}"
            remote_volume = remote_volumes.find { |v| v.label == volume_label }

            if remote_volume.nil?
              logger.info "volume \"%s\": %s" % [volume[:label], "does not exist"]
              next
            end

            logger.info format_volume(machine, remote_volume)
          end

          @app.call(env)
        end

        private

        def format_volume(machine, volume)
          volume_state = if volume.linodeid.to_s == machine.id
                           "attached"
                         elsif volume.linodeid == 0
                           "detached"
                         else
                           "attached to other VM"
                         end

          "volume \"%s\": %s" % [volume.label, volume_state]
        end
      end
    end
  end
end
