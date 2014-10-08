module VagrantPlugins
  module Linode
    module Actions
      class ListServers
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-8s %-30s %-20s %-10s %-9s' % ['LinodeID', 'Label', 'DataCenter', 'Plan', 'Status'])
          linode_api.linode.list.sort_by(&:imageid).each do |ln|
            env[:ui].info ('%-8s %-30s %-20s %-10s %-9s' % [ln.linodeid, ln.label, ln.datacenterid, ln.planid, ln.status])
          end
          @app.call(env)
        end
      end
    end
  end
end
