module VagrantPlugins
  module Linode
    module Actions
      class ListImages
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-10s %-22s %-10s %s' % ['Image ID', 'Created', 'Size (MB)', 'Image Label'])
          linode_api.image.list.sort_by(&:imageid).each do |img|
            env[:ui].info ('%-10s %-22s %-10s %s' % [img.imageid, img.create_dt, img.minsize, img.label])
          end
          @app.call(env)
        end
      end
    end
  end
end
