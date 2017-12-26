module VagrantPlugins
  module Linode
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :token # deprecated
      attr_accessor :api_key
      attr_accessor :api_url
      attr_accessor :distributionid
      attr_accessor :distribution
      attr_accessor :imageid
      attr_accessor :image
      attr_accessor :datacenterid
      attr_accessor :datacenter
      attr_accessor :planid
      attr_accessor :plan
      attr_accessor :paymentterm
      attr_accessor :private_networking
      attr_accessor :ca_path
      attr_accessor :ssh_key_name
      attr_accessor :setup
      attr_accessor :stackscriptid
      attr_accessor :stackscript
      attr_accessor :stackscript_udf_responses
      attr_accessor :xvda_size
      attr_accessor :swap_size
      attr_accessor :kernelid
      attr_accessor :kernel
      attr_accessor :label
      attr_accessor :group
      attr_accessor :volumes

      alias_method :setup?, :setup

      def initialize
        # @logger  = Log4r::Logger.new('vagrant::linode::config')

        @token              = UNSET_VALUE
        @api_key            = UNSET_VALUE
        @api_url            = UNSET_VALUE
        @distributionid     = UNSET_VALUE
        @distribution       = UNSET_VALUE
        @stackscriptid      = UNSET_VALUE
        @stackscript        = UNSET_VALUE
        @stackscript_udf_responses = UNSET_VALUE
        @imageid            = UNSET_VALUE
        @image              = UNSET_VALUE
        @datacenterid       = UNSET_VALUE
        @datacenter         = UNSET_VALUE
        @planid             = UNSET_VALUE
        @plan               = UNSET_VALUE
        @paymentterm        = UNSET_VALUE
        @private_networking = UNSET_VALUE
        @ca_path            = UNSET_VALUE
        @ssh_key_name       = UNSET_VALUE
        @setup              = UNSET_VALUE
        @xvda_size          = UNSET_VALUE
        @swap_size          = UNSET_VALUE
        @kernelid           = UNSET_VALUE
        @kernel             = UNSET_VALUE
        @label              = UNSET_VALUE
        @group              = UNSET_VALUE
        @volumes            = UNSET_VALUE
      end

      def finalize!
        @api_key            = ENV['LINODE_API_KEY'] if @api_key == UNSET_VALUE
        @token              = ENV['LINODE_TOKEN'] if @token == UNSET_VALUE
        @api_key            = @token if ((@api_key == nil) and (@token != nil))
        @api_url            = ENV['LINODE_URL'] if @api_url == UNSET_VALUE
        @imageid            = nil if @imageid == UNSET_VALUE
        @image              = nil if @image == UNSET_VALUE
        @distributionid     = nil if @distributionid == UNSET_VALUE
        @distribution       = nil if @distribution == UNSET_VALUE
        @distribution       = 'Ubuntu 16.04 LTS' if @distribution.nil? and @distributionid.nil? and @imageid.nil? and @image.nil?
        @stackscriptid      = nil if @stackscriptid == UNSET_VALUE
        @stackscript        = nil if @stackscript == UNSET_VALUE
        @stackscript_udf_responses = nil if @stackscript_udf_responses == UNSET_VALUE
        @datacenterid       = nil if @datacenterid == UNSET_VALUE
        @datacenter         = nil if @datacenter == UNSET_VALUE
        @datacenter         = 'dallas' if @datacenter.nil? and @datacenterid.nil?
        @planid             = nil if @planid == UNSET_VALUE
        @plan               = nil if @plan == UNSET_VALUE
        @planid             = '1' if @plan.nil? and @planid.nil?
        @paymentterm        = '1' if @paymentterm == UNSET_VALUE
        @private_networking = false if @private_networking == UNSET_VALUE
        @ca_path            = nil if @ca_path == UNSET_VALUE
        @ssh_key_name       = 'Vagrant' if @ssh_key_name == UNSET_VALUE
        @setup              = true if @setup == UNSET_VALUE
        @xvda_size          = true if @xvda_size == UNSET_VALUE
        @swap_size          = '256' if @swap_size == UNSET_VALUE
        @kernelid           = nil if @kernelid == UNSET_VALUE
        @kernel             = nil if @kernel == UNSET_VALUE
        @kernel             = 'Latest 64 bit' if @kernel.nil? and @kernelid.nil?
        @label              = false if @label == UNSET_VALUE
        @group              = false if @group == UNSET_VALUE
        @volumes            = [] if @volumes == UNSET_VALUE
      end

      def validate(machine)
        errors = []
        errors << I18n.t('vagrant_linode.config.api_key') unless @api_key
        # Log4r::Logger.new('vagrant_linode.config.token') if @token
        # env[:ui].info I18n.t('vagrant_linode.config.token') if @token
        # errors << I18n.t('vagrant_linode.config.token') if @token
        key = machine.config.ssh.private_key_path
        key = key[0] if key.is_a?(Array)
        if !key
          errors << I18n.t('vagrant_linode.config.private_key')
        elsif !File.file?(File.expand_path("#{key}.pub", machine.env.root_path))
          errors << I18n.t('vagrant_linode.config.public_key', key: "#{key}.pub")
        end

        if @distributionid and @distribution
          errors << I18n.t('vagrant_linode.config.distributionid_or_distribution')
        end

        if @stackscriptid and @stackscript
          errors << I18n.t('vagrant_linode.config.stackscriptid_or_stackscript')
        end

        if @datacenterid and @datacenter
          errors << I18n.t('vagrant_linode.config.datacenterid_or_datacenter')
        end

        if @kernelid and @kernel
          errors << I18n.t('vagrant_linode.config.kernelid_or_kernel')
        end

        if @planid and @plan
          errors << I18n.t('vagrant_linode.config.planid_or_plan')
        end

        if @imageid and @image
          errors << I18n.t('vagrant_linode.config.imageid_or_image')
        end

        if (@distribution or @distributionid) and (@imageid or @image)
          errors << I18n.t('vagrant_linode.config.distribution_or_image')
        end

        if !@volumes.is_a? Array
          errors << I18n.t("vagrant_linode.config.volumes")
        end

        { 'Linode Provider' => errors }
      end
    end
  end
end
