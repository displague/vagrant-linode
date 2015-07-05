module VagrantPlugins
  module Linode
    module Actions
      class CreateImage
        def initialize(app, _env)
          @app = app
	  @machine = _env[:machine]
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-36s %-36s %-10s %-10s' % ['Image ID', 'Disk Label', 'Disk ID', 'Job ID'])
          linode_api.linode.disk.list(:linodeid => @machine.id).each do |disk|
            next if disk.type == 'swap'
	    img = linode_api.linode.disk.imagize :linodeid => disk.linodeid, :diskid => disk.diskid, :description => 'Imagized with Vagrant'
            env[:ui].info ('%-36s %-36s %-10s %-10s' % [img.imageid, disk.label, disk.diskid, img.jobid])
          end
          @app.call(env)
        end
      end
    end
  end
end
