require 'vagrant-linode/helpers/result'
require 'linodeapi'
require 'json'
require 'vagrant/util/retryable'

include Vagrant::Util::Retryable

module VagrantPlugins
  module Linode
    module Helpers
#      module Client
#        def client
#          def wait_for_event(env, id)
#            retryable(tries: 120, sleep: 10) do
#              # stop waiting if interrupted
#              next if env[:interrupted]
#              # check action status
#              result = @client.linode.job.list(jobid: id, linodeid: env[:machine].id)
#              result = result[0] if result.is_a?(Array)
#
#              yield result if block_given?
#              fail 'not ready' if result['host_finish_dt'] > ''
#            end
#          end
#          linodeapi = ::LinodeAPI::Raw.new(apikey: @machine.provider_config.api_key,
#                                           endpoint: @machine.provider_config.api_url || nil)
#          # linodeapi.wait_for_event = wait_for_event
#          # linodeapi.extend wait_for_event
#        end
#      end

      class ApiClient
        include Vagrant::Util::Retryable

        def initialize(machine)
          @logger = Log4r::Logger.new('vagrant::linode::apiclient')
          @config = machine.provider_config
          @client = ::LinodeAPI::Retryable.new(apikey: @config.api_key, endpoint: @config.api_url || nil)
        end

        attr_reader :client

        def wait_for_event(env, id)
          retryable(tries: 120, sleep: 10) do
            # stop waiting if interrupted
            next if env[:interrupted]

            # check action status
            result = @client.linode.job.list(jobid: id, linodeid: env[:machine].id)

            yield result if block_given?
            fail 'not ready' if result['host_finish_dt'] > ''
          end
        end
      end
    end
  end
end
