require "log4r"

module VagrantPlugins
  module Linode
    class ClientWrapper
      def initialize(client, logger)
        @client = client
        @logger = logger
      end

      def method_missing(method, *args, &block)
        result = @client.send(method, *args, &block)

        if result.is_a? LinodeAPI::Retryable
          self.class.new(result, @logger)
        else
          result
        end
      rescue ::LinodeAPI::APIError => e
        @logger.error e.details.inspect
        raise
      end
    end
  end
end
