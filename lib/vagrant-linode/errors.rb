module VagrantPlugins
  module Linode
    module Errors
      class LinodeError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_linode.errors")
      end

      class APIStatusError < LinodeError
        error_key(:api_status)
      end

      class JSONError < LinodeError
        error_key(:json)
      end

      class ResultMatchError < LinodeError
        error_key(:result_match)
      end

      class CertificateError < LinodeError
        error_key(:certificate)
      end

      class LocalIPError < LinodeError
        error_key(:local_ip)
      end

      class PublicKeyError < LinodeError
        error_key(:public_key)
      end

      class RsyncError < LinodeError
        error_key(:rsync)
      end
    end
  end
end
