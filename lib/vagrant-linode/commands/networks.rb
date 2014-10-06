module VagrantPlugins
  module Linode
    module Commands
      class Networks < Vagrant.plugin("2", :command)
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant linode networks [options]"
          end

          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, :provider => :linode) do |machine|
            machine.action('list_networks')
          end
        end
      end
    end
  end
end
