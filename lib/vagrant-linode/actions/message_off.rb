module VagrantPlugins
  module Linode
    module Actions
      class MessageOff
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_linode.info.off", :status => :off))
          @app.call(env)
        end
      end
    end
  end
end
