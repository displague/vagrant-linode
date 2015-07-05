module VagrantPlugins
  module Linode
    module Actions
      class IsStopped
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          env[:result] = env[:machine].state.id == :off

          @app.call(env)
        end
      end
    end
  end
end
