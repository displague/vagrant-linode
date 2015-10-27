module VagrantPlugins
  module Linode
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :token # deprecated
      attr_accessor :api_key
      attr_accessor :api_url
      attr_accessor :distribution
      attr_accessor :image_id
      attr_accessor :datacenter
      attr_accessor :plan
      attr_accessor :paymentterm
      attr_accessor :private_networking
      attr_accessor :ca_path
      attr_accessor :ssh_key_name
      attr_accessor :setup
      attr_accessor :xvda_size
      attr_accessor :swap_size
      attr_accessor :kernel_id
      attr_accessor :kernel
      attr_accessor :label
      attr_accessor :group

      alias_method :setup?, :setup

      def initialize
        # @logger  = Log4r::Logger.new('vagrant::linode::config')

        @token              = UNSET_VALUE
        @api_key            = UNSET_VALUE
        @api_url            = UNSET_VALUE
        @distribution       = UNSET_VALUE
        @image_id           = UNSET_VALUE
        @datacenter         = UNSET_VALUE
        @plan               = UNSET_VALUE
        @paymentterm        = UNSET_VALUE
        @private_networking = UNSET_VALUE
        @ca_path            = UNSET_VALUE
        @ssh_key_name       = UNSET_VALUE
        @setup              = UNSET_VALUE
        @xvda_size          = UNSET_VALUE
        @swap_size          = UNSET_VALUE
        @kernel_id          = UNSET_VALUE
        @kernel             = UNSET_VALUE
        @label              = UNSET_VALUE
        @group              = UNSET_VALUE
      end

      def finalize!
        @api_key            = ENV['LINODE_API_KEY'] if @api_key == UNSET_VALUE
        @token              = ENV['LINODE_TOKEN'] if @token == UNSET_VALUE
        @api_key            = @token if ((@api_key == nil) and (@token != nil))
        @api_url            = ENV['LINODE_URL'] if @api_url == UNSET_VALUE
        @distribution       = 'Ubuntu 14.04 LTS' if @distribution == UNSET_VALUE
        @image_id           = nil if @image_id == UNSET_VALUE
        @datacenter         = 'dallas' if @datacenter == UNSET_VALUE
        @plan               = 'Linode 1024' if @plan == UNSET_VALUE
        @paymentterm        = '1' if @paymentterm == UNSET_VALUE
        @private_networking = false if @private_networking == UNSET_VALUE
        @ca_path            = nil if @ca_path == UNSET_VALUE
        @ssh_key_name       = 'Vagrant' if @ssh_key_name == UNSET_VALUE
        @setup              = true if @setup == UNSET_VALUE
        @xvda_size          = true if @xvda_size == UNSET_VALUE
        @swap_size          = '256' if @swap_size == UNSET_VALUE
        @kernel             = 'Latest 64 bit' if @kernel == UNSET_VALUE and @kernel_id == UNSET_VALUE
        @label              = false if @label == UNSET_VALUE
        @group              = false if @group == UNSET_VALUE
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

        { 'Linode Provider' => errors }
      end
    end
  end
end
