require 'vagrant-linode/helpers/result'
require 'linodeapi'
require 'json'
require 'vagrant/util/retryable'

include Vagrant::Util::Retryable

module VagrantPlugins
  module Linode
    module Helpers
      module Client
        def client
          def wait_for_event(env, id)
            retryable(tries: 120, sleep: 10) do
              # stop waiting if interrupted
              next if env[:interrupted]
              # check action status
              result = @client.linode.job.list(jobid: id, linodeid: env[:machine].id)
              result = result[0] if result.is_a?(Array)

              yield result if block_given?
              fail 'not ready' if result['host_finish_dt'] > ''
            end
          end
          linodeapi = ::LinodeAPI::Raw.new(apikey: @machine.provider_config.token,
				      endpoint: @machine.provider_config.api_url || nil)
          # linodeapi.wait_for_event = wait_for_event
          # linodeapi.extend wait_for_event
        end
      end

      class ApiClient
        include Vagrant::Util::Retryable

        def initialize(machine)
          @logger = Log4r::Logger.new('vagrant::linode::apiclient')
          @config = machine.provider_config
	  @client = ::LinodeAPI::Raw.new(apikey: @config.token, endpoint: @config.api_url || nil)
        end

        attr_reader :client

        def delete(path, params = {}, _method = :delete)
          @client.request :url_encoded
          request(path, params, :delete)
        end

        def post(path, params = {}, _method = :post)
          @client.headers['Content-Type'] = 'application/json'
          request(path, params, :post)
        end

        def request(path, params = {}, method = :get)
          begin
            @logger.info "Request: #{path}"
            result = @client.send(method) do |req|
              req.url path, params
              req.headers['Authorization'] = "Bearer #{@config.token}"
            end
          rescue Faraday::Error::ConnectionFailed => e
            # TODO this is suspect but because farady wraps the exception
            #      in something generic there doesn't appear to be another
            #      way to distinguish different connection errors :(
            if e.message =~ /certificate verify failed/
              raise Errors::CertificateError
            end

            raise e
          end

          unless method == :delete
            begin
              body = JSON.parse(result.body)
              @logger.info "Response: #{body}"
              next_page = body['links']['pages']['next'] rescue nil
              unless next_page.nil?
                uri = URI.parse(next_page)
                new_path = path.split('?')[0]
                next_result = request("#{new_path}?#{uri.query}")
                req_target = new_path.split('/')[-1]
                body["#{req_target}"].concat(next_result["#{req_target}"])
              end
            rescue JSON::ParserError => e
              raise(Errors::JSONError, message: e.message,
                                       path: path,
                                       params: params,
                                       response: result.body)
            end
          end

          unless /^2\d\d$/ =~ result.status.to_s
            fail(Errors::APIStatusError, path: path,
                                         params: params,
                                         status: result.status,
                                         response: body.inspect)
          end

          Result.new(body)
        end

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
