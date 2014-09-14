require 'vagrant-linode/actions/check_state'
require 'vagrant-linode/actions/create'
require 'vagrant-linode/actions/destroy'
require 'vagrant-linode/actions/power_off'
require 'vagrant-linode/actions/power_on'
require 'vagrant-linode/actions/rebuild'
require 'vagrant-linode/actions/reload'
require 'vagrant-linode/actions/setup_user'
require 'vagrant-linode/actions/setup_sudo'
require 'vagrant-linode/actions/setup_key'
require 'vagrant-linode/actions/sync_folders'
require 'vagrant-linode/actions/modify_provision_path'

module VagrantPlugins
  module Linode
    module Actions
      include Vagrant::Action::Builtin

      def self.destroy
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

      def self.ssh
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

      def self.ssh_run
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

      def self.provision
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

      def self.up
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active
              env[:ui].info I18n.t('vagrant_linode.info.already_active')
            when :off
              b.use PowerOn
              b.use provision
            when 0
              # b.use SetupKey # no access to ssh keys in linode api
              b.use Create
              b.use SetupSudo
              b.use SetupUser
              b.use provision
            end
          end
        end
      end

      def self.halt
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

      def self.reload
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

      def self.rebuild
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, CheckState do |env, b|
            case env[:machine_state]
            when :active, :off
              b.use Rebuild
              b.use SetupSudo
              b.use SetupUser
              b.use provision
            when :not_created
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end
    end
  end
end
