@announce
@vagrant-linode
Feature: vagrant-linode fog tests

  Background:
    Given I have Linode credentials available
    And I have a "fog_mock.rb" file

  Scenario: Create a single server (with provisioning)
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure("2") do |config|
      Vagrant.require_plugin "vagrant-linode"

      config.vm.box = "dummy"
      config.ssh.private_key_path = "~/.ssh/id_rsa"


      config.vm.provider :linode do |provider|
        provider.server_name = 'vagrant-provisioned-server'
        provider.api_key  = ENV['LINODE_API_KEY']
        provider.datacenter   = 'dallas'
        provider.plan   = /Linode 1024/
        provider.distribution    = /Ubuntu/
        provider.public_key_path = "~/.ssh/id_rsa.pub"
      end

      config.vm.provision :shell, :inline => "echo Hello, World"
    end
    """
    When I successfully run `bundle exec vagrant up --provider linode`
    # I want to capture the ID like I do in tests for other tools, but Vagrant doesn't print it!
    # And I get the server from "Instance ID:"
    Then the server "vagrant-provisioned-server" should be active
