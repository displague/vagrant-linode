require 'pathname'

require 'vagrant/action/builder'

module VagrantPlugins
  module Linode
    module Actions
      include Vagrant::Action::Builtin

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            else
              b.use Call, DestroyConfirm do |env2, b2|
                if env2[:result]
                  b2.use Destroy
                  b2.use ProvisionerCleanup if defined?(ProvisionerCleanup)
                end
              end
            end
          end
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              b.use SSHExec
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              b.use SSHRun
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              b.use Provision
              b.use ModifyProvisionPath
              b.use SyncFolders
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              env[:ui].info I18n.t('vagrant_linode.info.already_active')
            when :off
              b.use PowerOn
              b.use provision
            when :not_created
              # b.use SetupKey # no access to ssh keys in linode api
              b.use Create
              b.use SetupSudo
              b.use SetupUser
              b.use SetupHostname
              b.use provision
            end
          end
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              b.use PowerOff
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.already_off')
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              b.use Reload
              b.use provision
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_rebuild
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active, :off
              b.use Rebuild
              b.use SetupSudo
              b.use SetupUser
              b.use SetupHostname
              b.use provision
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      # Extended actions
      def self.action_list_images
	      Vagrant::Action::Builder.new.tap do |b|
		      # b.use ConfigValidate # is this per machine?
		      b.use ListImages
	      end
      end

      def self.action_list_plans
	      Vagrant::Action::Builder.new.tap do |b|
		      # b.use ConfigValidate # is this per machine?
		      b.use ListPlans
	      end
      end


      action_root = Pathname.new(File.expand_path('../actions', __FILE__))
      autoload :CheckState, action_root.join('check_state')
      autoload :Create, action_root.join('create')
      autoload :Destroy, action_root.join('destroy')
      autoload :ModifyProvisionPath, action_root.join('modify_provision_path')
      autoload :PowerOff, action_root.join('power_off')
      autoload :PowerOn, action_root.join('power_on')
      autoload :Destroy, action_root.join('destroy')
      autoload :Reload, action_root.join('reload')
      autoload :Rebuild, action_root.join('rebuild')
      autoload :SetupHostname, action_root.join('setup_hostname')
      autoload :SetupKey, action_root.join('setup_key')
      autoload :SetupUser, action_root.join('setup_user')
      autoload :SetupSudo, action_root.join('setup_sudo')
      autoload :SyncFolders, action_root.join('sync_folders')
      autoload :ListImages, action_root.join('list_images')
      autoload :ListPlans, action_root.join('list_plans')

    end
  end
end
