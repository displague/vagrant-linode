require 'vagrant-linode/helpers/client'
require 'vagrant-linode/actions'

module VagrantPlugins
  module Linode
    class Provider < Vagrant.plugin('2', :provider)
      def initialize(machine)
        @machine = machine
      end

      # This class method caches status for all linodes within
      # the Linode account. A specific linode's status
      # may be refreshed by passing :refresh => true as an option.
      def self.linode(machine, opts = {})
        client = Helpers::ApiClient.new(machine).client

        # @todo how do I reuse VagrantPlugins::Linode::Actions::ConnectLinode ?
        # ..and nuke the helper
        # client = env[:linode_api]

        # load status of linodes if it has not been done before
        unless @linodes
          @linodes = client.linode.list.each { |l| l.network = client.linode.ip.list linodeid: l.linodeid }
        end

        if opts[:refresh] && machine.id
          # refresh the linode status for the given machine
          @linodes.delete_if { |d| d['linodeid'].to_s == machine.id }
          linode = client.linode.list(linodeid: machine.id).first
          linode.network = client.linode.ip.list linodeid: linode['linodeid']
          @linodes << linode
        else
          # lookup linode status for the given machine
          linode = @linodes.find { |d| d['linodeid'].to_s == machine.id }
        end

        # if lookup by id failed, check for a linode with a matching name
        # and set the id to ensure vagrant stores locally
        # TODO allow the user to configure this behavior
        unless linode
          name = machine.config.vm.hostname || machine.name
          linode = @linodes.find { |d| d['label'] == name.to_s }
          machine.id = linode['linodeid'].to_s if linode
        end

        linode ||= { status: :not_created }
      end

      # Attempt to get the action method from the Action class if it
      # exists, otherwise return nil to show that we don't support the
      # given action.
      def action(name)
        action_method = "action_#{name}"
        return Actions.send(action_method) if Actions.respond_to?(action_method)
        nil
      end

      # This method is called if the underying machine ID changes. Providers
      # can use this method to load in new data for the actual backing
      # machine or to realize that the machine is now gone (the ID can
      # become `nil`). No parameters are given, since the underlying machine
      # is simply the machine instance given to this object. And no
      # return value is necessary.
      def machine_id_changed
        linode(@machine, refresh: true)
      end

      # This should return a hash of information that explains how to
      # SSH into the machine. If the machine is not at a point where
      # SSH is even possible, then `nil` should be returned.
      #
      # The general structure of this returned hash should be the
      # following:
      #
      #     {
      #       :host => "1.2.3.4",
      #       :port => "22",
      #       :username => "mitchellh",
      #       :private_key_path => "/path/to/my/key"
      #     }
      #
      # **Note:** Vagrant only supports private key based authenticatonion,
      # mainly for the reason that there is no easy way to exec into an
      # `ssh` prompt with a password, whereas we can pass a private key
      # via commandline.
      def ssh_info
        env = @machine.action('read_ssh_info')
        env[:machine_ssh_info]
      end

      # This should return the state of the machine within this provider.
      # The state must be an instance of {MachineState}. Please read the
      # documentation of that class for more information.
      def state
        env = @machine.action('read_state')
        state_id = env[:machine_state_id]

        short = I18n.t("vagrant_linode.states.short_#{state_id}")
        long = I18n.t("vagrant_linode.states.long_#{state_id}")

        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? 'new' : @machine.id
        "Linode (#{id})"
      end
    end
  end
end
