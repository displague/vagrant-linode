module VagrantPlugins
  module Linode
    module Actions
      class MessageNotCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_linode.info.not_created", :status => :not_created))
          @app.call(env)
        end
      end
    end
  end
end
