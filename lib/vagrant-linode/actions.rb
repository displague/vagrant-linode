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
            if !env[:result]
              b.use MessageNotCreated
            else
              b.use Call, DestroyConfirm do |env2, b2|
                if env2[:result]
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
            if env[:result]
              b.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use MessageOff
                else
                  b2.use SSHExec
                end
              end
            else
              b.use MessageNotCreated
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            if env[:result]
              b.use SSHRun
            else
              b.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use MessageOff
                else
                  b2.use MessageNotCreated
                end
              end
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            if env[:result]
              b.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use MessageOff
                else
                  b2.use Provision
                  b2.use ModifyProvisionPath
                  b2.use SyncedFolders
                end
              end
            else
              b.use MessageNotCreated
            end
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            if env[:result]
              b.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use Provision
                  b2.use SyncedFolders
                  b2.use MessageOff
                  b2.use ConnectLinode
                  b2.use PowerOn
                else
                  b2.use MessageAlreadyActive
                end
              end
            else
              b.use Provision
              b.use SyncedFolders
              b.use MessageNotCreated
              b.use ConnectLinode
              b.use Create
              b.use SetupSudo
              b.use SetupUser
              b.use SetupHostname
            end
          end
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b1|
            if env[:result]
              b1.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use MessageAlreadyOff
                else
                  b2.use ConnectLinode
                  b2.use PowerOff
                end
              end
            else
              b1.use MessageNotCreated
            end
          end
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            if env[:result]
              b.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use MessageOff
                else
                  b2.use ConnectLinode
                  b2.use Reload
                  b2.use Provision
                end
              end
            else
              b.use MessageNotCreated
            end
          end
        end
      end

      def self.action_rebuild
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Call, IsCreated do |env, b|
            if env[:result]
              b.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use ConnectLinode
                  b2.use Rebuild
                  b2.use SetupSudo
                  b2.use SetupUser
                  b2.use SetupHostname
                  b2.use Provision
                else
                  b2.use MessageNotOff
                end
              end
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # Extended actions
      def self.action_create_image
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use CreateImage
        end
      end

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

      def self.action_list_kernels
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListKernels
        end
      end

      def self.action_list_volumes
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate # is this per machine?
          b.use ConnectLinode
          b.use ListVolumes
        end
      end

      action_root = Pathname.new(File.expand_path('../actions', __FILE__))
      autoload :ConnectLinode, action_root.join('connect_linode')
      autoload :ReadState, action_root.join('read_state')
      autoload :Create, action_root.join('create')
      autoload :IsCreated, action_root.join('is_created')
      autoload :IsStopped, action_root.join('is_stopped')
      autoload :MessageAlreadyActive, action_root.join('message_already_active')
      autoload :MessageAlreadyOff, action_root.join('message_already_off')
      autoload :MessageNotOff, action_root.join('message_not_off')
      autoload :MessageNotCreated, action_root.join('message_not_created')
      autoload :MessageOff, action_root.join('message_off')
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
      autoload :ListServers, action_root.join('list_servers')
      autoload :CreateImage, action_root.join('create_image')
      autoload :ListImages, action_root.join('list_images')
      autoload :ListPlans, action_root.join('list_plans')
      autoload :ListDistributions, action_root.join('list_distributions')
      autoload :ListKernels, action_root.join('list_kernels')
      autoload :ListDatacenters, action_root.join('list_datacenters')
      autoload :ListVolumes, action_root.join('list_volumes')
    end
  end
end
