module VagrantPlugins
  module Linode
    module Actions
      class ListDatacenters
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-15s %-36s %s' % ['Datacenter ID', 'Location', 'Abbr'])
          linode_api.avail.datacenters.sort_by(&:datacenterid).each do |dc|
            env[:ui].info ('%-15s %-36s %s' % [dc.datacenterid, dc.location, dc.abbr])
          end
          @app.call(env)
        end
      end
    end
  end
end
