module VagrantPlugins
  module Linode
    module Commands
      class ListVolumes < Vagrant.plugin('2', :command)
        def execute
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant linode volumes list [options]'
          end

          argv = parse_options(opts)
          return unless argv

          with_target_vms(argv) do |machine|
            machine.action(:list_volumes)
          end
        end
      end
    end
  end
end
