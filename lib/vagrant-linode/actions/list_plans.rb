module VagrantPlugins
  module Linode
    module Actions
      class ListPlans
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-36s %s' % ['Plan ID', 'Plan Name'])
          linode_api.avail.linodeplans.sort_by(&:planid).each do |plan|
            env[:ui].info ('%-36s %s' % [plan.planid, plan.label])
          end
          @app.call(env)
        end
      end
    end
  end
end
