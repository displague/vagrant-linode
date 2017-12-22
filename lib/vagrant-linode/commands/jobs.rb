module VagrantPlugins
  module Linode
    module Commands
      class Jobs < Vagrant.plugin('2', :command)
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant linode jobs [options]'
          end

          argv = parse_options(opts)
          return unless argv

          with_target_vms(argv, provider: :linode) do |machine|
            machine.action('list_jobs')
          end
        end
      end
    end
  end
end
