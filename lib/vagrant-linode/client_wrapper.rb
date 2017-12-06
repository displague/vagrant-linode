require "log4r"

module VagrantPlugins
  module Linode
    class ClientWrapper
      def initialize(client, ui)
        @client = client
        @ui = ui
      end

      def method_missing(method, *args, &block)
        result = @client.send(method, *args, &block)

        if result.is_a? LinodeAPI::Retryable
          self.class.new(result, @ui)
        else
          result
        end
      rescue ::LinodeAPI::APIError => e
        @ui.error e.details.inspect
        raise
      end
    end
  end
end
