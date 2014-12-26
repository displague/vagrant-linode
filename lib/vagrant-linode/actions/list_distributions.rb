module VagrantPlugins
  module Linode
    module Actions
      class ListDistributions
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-4s %-6s %s' % ['ID', 'Size', 'Distribution Name'])
          linode_api.avail.distributions.sort_by(&:distributionid).each do |dist|
            env[:ui].info ('%-4s %-6s %s' % [dist.distributionid, dist.minimagesize, dist.label])
          end
          @app.call(env)
        end
      end
    end
  end
end
