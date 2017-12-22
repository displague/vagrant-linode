module VagrantPlugins
  module Linode
    module Actions
      class ListJobs
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          linode_api = env[:linode_api]
          env[:ui].info ('%-7s %-18s %-12s %s' % ['ID', 'Action', 'Duration', 'Job Name'])
          linode_api.linode.job.list(env[:machine].id).sort_by(&:jobid).each do |job|
            env[:ui].info ('%-7s %-18s %-12s %s' % [job.jobid, job.action, job.duration, job.label])
          end
          @app.call(env)
        end
      end
    end
  end
end
