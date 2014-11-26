module VagrantPlugins
  module Linode
    module Helpers
      module Waiter
        include Vagrant::Util::Retryable
        def wait_for_event(env, id)
          retryable(tries: 120, sleep: 10) do
            # stop waiting if interrupted
            next if env[:interrupted]
            # check action status
            result = env[:linode_api].linode.job.list(jobid: id, linodeid: env[:machine].id)
            result = result[0] if result.is_a?(Array)

            yield result if block_given?
            fail 'not ready' if result['host_finish_dt'] > ''
          end
        end
      end
    end
  end
end
