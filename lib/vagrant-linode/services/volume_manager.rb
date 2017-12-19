require "vagrant-linode/errors"

module VagrantPlugins
  module Linode
    module Services
      class VolumeManager
        def initialize(machine, api, logger)
          @machine = machine
          @volumes_api = api
          @logger = logger
        end

        def perform
          volume_definitions.each do |volume|
            raise Errors::VolumeLabelMissing if volume[:label].to_s.empty?

            volume_name = "#{@machine.name}_#{volume[:label]}"

            remote_volume = remote_volumes.find { |v| v.label == volume_name }
            if remote_volume
              attach_volume(remote_volume)
            else
              create_and_attach_volume(volume_name, volume[:size])
            end
          end
        end

        private

        def volume_definitions
          @machine.provider_config.volumes
        end

        def remote_volumes
          @_remote_volumes ||= @volumes_api.list
        end

        def attach_volume(volume)
          @volumes_api.update(
            volumeid: volume.volumeid,
            linodeid: @machine.id
          )
          @logger.info "volume #{volume.label} attached"
        end

        def create_and_attach_volume(label, size)
          raise Errors::VolumeSizeMissing unless size.to_i > 0

          @volumes_api.create(
            label: label,
            size: size,
            linodeid: @machine.id
          )
          @logger.info "volume #{label} created and attached"
        end
      end
    end
  end
end
