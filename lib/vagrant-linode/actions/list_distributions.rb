module VagrantPlugins
  module Linode
    module Actions
      class ListDistributions
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-36s %s' % ['Distribution ID', 'Distribution Name'])
          linode_api.avail.distributions.sort_by(&:distributionid).each do |dist|
            env[:ui].info ('%-36s %s' % [dist.distributionid, dist.label])
          end
          @app.call(env)
        end
      end
    end
  end
end
