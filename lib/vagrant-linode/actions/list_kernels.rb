module VagrantPlugins
  module Linode
    module Actions
      class ListKernels
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-4s %-6s %-6s %s' % ['ID', 'IsXen', 'IsKVM', 'Kernel Name'])
          linode_api.avail.kernels(isxen: nil, iskvm: 1).sort_by(&:kernelid).each do |kernel|
            env[:ui].info ('%-4s %-6s %-6s %s' % [kernel.kernelid, kernel.isxen, kernel.iskvm, kernel.label])
          end
          @app.call(env)
        end
      end
    end
  end
end
