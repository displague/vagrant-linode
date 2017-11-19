module VagrantPlugins
  module Linode
    module Actions
      class MessageNotOff
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_linode.info.not_off"))
          @app.call(env)
        end
      end
    end
  end
end
