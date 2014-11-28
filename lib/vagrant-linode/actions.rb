require 'pathname'

require 'vagrant/action/builder'

module VagrantPlugins
  module Linode
    module Actions
      include Vagrant::Action::Builtin

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            else
              b.use Call, DestroyConfirm do |env2, b2|
                if env2[:machine_state]
                  b2.use ConnectLinode
                  b2.use Destroy
                  b2.use ProvisionerCleanup if defined?(ProvisionerCleanup)
                end
              end
            end
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectLinode
          b.use ReadSSHInfo
        end
      end

      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectLinode
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active
              b.use SSHExec
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active
              b.use SSHRun
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active
              b.use Provision
              b.use ModifyProvisionPath
              b.use SyncFolders
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active
              b.use Message, I18n.t("vagrant_linode.info.already_active")
	      next
            when :off
              b.use Message, I18n.t("vagrant_linode.info.off")
              b.use ConnectLinode
              b.use PowerOn
              b.use Provision
            when :not_created, false
              b.use Message, I18n.t("vagrant_linode.info.not_created")
              # b.use SetupKey # no access to ssh keys in linode api
              b.use ConnectLinode
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
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active
              b.use ConnectLinode
              b.use PowerOff
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.already_off')
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active
              b.use ConnectLinode
              b.use Reload
              b.use Provision
            when :off
              env[:ui].info I18n.t('vagrant_linode.info.off')
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      def self.action_rebuild
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            case env[:machine_state]
            when :active, :off
              b.use ConnectLinode
              b.use Rebuild
              b.use SetupSudo
              b.use SetupUser
              b.use SetupHostname
              b.use provision
            when :not_created
              b.use Provision
            when :not_created, false
              env[:ui].info I18n.t('vagrant_linode.info.not_created')
            end
          end
        end
      end

      # Extended actions
      def self.action_list_images
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListImages
        end
      end

      def self.action_list_servers
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListServers
        end
      end

      def self.action_list_plans
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListPlans
        end
      end

      def self.action_list_datacenters
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListDatacenters
        end
      end

      def self.action_list_distributions
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListDistributions
        end
      end

      action_root = Pathname.new(File.expand_path('../actions', __FILE__))
      autoload :ConnectLinode, action_root.join('connect_linode')
      autoload :ReadState, action_root.join('read_state')
      autoload :Create, action_root.join('create')
      autoload :Destroy, action_root.join('destroy')
      autoload :IsCreated, action_root.join('is_created')
      autoload :ModifyProvisionPath, action_root.join('modify_provision_path')
      autoload :PowerOff, action_root.join('power_off')
      autoload :PowerOn, action_root.join('power_on')
      autoload :Destroy, action_root.join('destroy')
      autoload :Reload, action_root.join('reload')
      autoload :Rebuild, action_root.join('rebuild')
      autoload :SetupHostname, action_root.join('setup_hostname')
      autoload :SetupUser, action_root.join('setup_user')
      autoload :SetupSudo, action_root.join('setup_sudo')
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :SyncFolders, action_root.join('sync_folders')
      autoload :ListServers, action_root.join('list_servers')
      autoload :ListImages, action_root.join('list_images')
      autoload :ListPlans, action_root.join('list_plans')
      autoload :ListDistributions, action_root.join('list_distributions')
      autoload :ListDatacenters, action_root.join('list_datacenters')
    end
  end
end
