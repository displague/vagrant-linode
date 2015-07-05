require "log4r"
require "timeout"

module VagrantPlugins
  module Linode
    module Action
      # This action will wait for a machine to reach a specific state or quit by timeout
      class WaitForEvent
        # env[:result] will be false in case of timeout.
        # @param [Symbol] state Target machine state.
        # @param [Number] timeout Timeout in seconds.
        def initialize(app, env, jobid, timeout)
          @app     = app
          @logger  = Log4r::Logger.new("vagrant_linode::action::wait_for_event")
          @state   = state
          @timeout = timeout
        end

        def call(env)
          env[:result] = true
          @logger.info("Waiting for event #{@jobid} to complete")
          begin
            Timeout.timeout(@timeout) do
              result = env[:client].linode.job.list(jobid:@jobid, linodeid: env[:machine].id)
              until result[:host_finish_dt] > ''
                sleep 2
              end
            end
          rescue Timeout::Error
            env[:result] = false # couldn't reach state in time
          end

          @app.call(env)
        end
      end
    end
  end
end
