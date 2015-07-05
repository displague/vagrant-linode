module VagrantPlugins
  module Linode
    module Actions
      class MessageAlreadyActive
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_linode.info.already_active", :status => :active))
          @app.call(env)
        end
      end
    end
  end
end
