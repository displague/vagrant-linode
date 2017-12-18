module VagrantPlugins
  module Linode
    module Errors
      class LinodeError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_linode.errors')
      end

      class APIStatusError < LinodeError
        error_key(:api_status)
      end

      class DiskSize < LinodeError
        error_key(:disk_size)
      end

      class DistroMatch < LinodeError
        error_key(:distro_match)
      end

      class DatacenterMatch < LinodeError
        error_key(:datacenter_match)
      end

      class ImageMatch < LinodeError
        error_key(:image_match)
      end

      class KernelMatch < LinodeError
        error_key(:kernel_match)
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

      class PlanID < LinodeError
        error_key(:plan_id)
      end

      class PublicKeyError < LinodeError
        error_key(:public_key)
      end

      class RsyncError < LinodeError
        error_key(:rsync)
      end

      class StackscriptMatch < LinodeError
        error_key(:stackscript_match)
      end

      class StackscriptUDFFormat < LinodeError
        error_key(:stackscript_udf_responses)
      end

      class VolumeSizeMissing < LinodeError
        error_key(:volume_size_missing)
      end

      class VolumeLabelMissing < LinodeError
        error_key(:volume_label_missing)
      end
    end
  end
end
