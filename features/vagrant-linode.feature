@announce
@vagrant-linode
Feature: vagrant-linode fog tests
  As a Fog developer
  I want to smoke (or "fog") test vagrant-linode.
  So I am confident my upstream changes did not create downstream problems.

  Background:
    Given I have Rackspace credentials available
    And I have a "fog_mock.rb" file

  Scenario: Create a single server (region)
    Given a file named "Vagrantfile" with:
    """
    # Testing options
    require File.expand_path '../fog_mock', __FILE__

    Vagrant.configure("2") do |config|
      # dev/test method of loading plugin, normally would be 'vagrant plugin install vagrant-linode'
      Vagrant.require_plugin "vagrant-linode"

      config.vm.box = "dummy"
      config.ssh.username = "vagrant" if Fog.mock?
      config.ssh.private_key_path = "~/.ssh/id_rsa" unless Fog.mock?

      config.vm.provider :linode do |provider|
        provider.server_name = 'vagrant-single-server'
        provider.api_key  = ENV['LINODE_API_KEY']
        linode.datacenter = ENV['LINODE_DATACENTER'].downcase.to_sym
        linode.plan   = /Linode 1024/
        linode.distribution    = /Ubuntu/
        linode.public_key_path = "~/.ssh/id_rsa.pub" unless Fog.mock?
      end
    end
    """
    When I successfully run `bundle exec vagrant up --provider linode`
    # I want to capture the ID like I do in tests for other tools, but Vagrant doesn't print it!
    # And I get the server from "Instance ID:"
    Then the server "vagrant-single-server" should be active

Scenario: Create a single server (linode_compute_url)
    Given a file named "Vagrantfile" with:
    """
    # Testing options
    require File.expand_path '../fog_mock', __FILE__

    Vagrant.configure("2") do |config|
      # dev/test method of loading plugin, normally would be 'vagrant plugin install vagrant-linode'
      Vagrant.require_plugin "vagrant-linode"

      config.vm.box = "dummy"
      config.ssh.username = "vagrant" if Fog.mock?
      config.ssh.private_key_path = "~/.ssh/id_rsa" unless Fog.mock?

      config.vm.provider :linode do |provider|
        provider.server_name = 'vagrant-single-server'
        provider.api_key  = ENV['LINODE_API_KEY']
        provider.api_url = "https://api.linode.com/"
        provider.plan   = /Linode 1024/
        provider.distribution    = /Ubuntu/
        provider.public_key_path = "~/.ssh/id_rsa.pub" unless Fog.mock?
      end
    end
    """
    When I successfully run `bundle exec vagrant up --provider linode`
    # I want to capture the ID like I do in tests for other tools, but Vagrant doesn't print it!
    # And I get the server from "Instance ID:"
    Then the server "vagrant-single-server" should be active
