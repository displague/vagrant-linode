require 'vagrant-linode/actions'

module VagrantPlugins
  module Linode
    module Commands
      class Root < Vagrant.plugin('2', :command)
        def self.synopsis
          'query Linode for available images or plans'
        end

        def initialize(argv, env)
          @main_args, @sub_command, @sub_args = split_main_and_subcommand(argv)

          @subcommands = Vagrant::Registry.new
          @subcommands.register(:images) do
            require File.expand_path('../images', __FILE__)
            Images
          end
          @subcommands.register(:plans) do
            require File.expand_path('../plans', __FILE__)
            Plans
          end
          @subcommands.register(:distributions) do
            require File.expand_path('../distributions', __FILE__)
            Distributions
          end
          @subcommands.register(:datacenters) do
            require File.expand_path('../datacenters', __FILE__)
            Datacenters
          end
          @subcommands.register(:keypairs) do
            require File.expand_path('../keypairs', __FILE__)
            KeyPairs
          end
          @subcommands.register(:networks) do
            require File.expand_path('../networks', __FILE__)
            Networks
          end
          @subcommands.register(:servers) do
            require File.expand_path('../servers', __FILE__)
            Servers
          end

          super(argv, env)
        end

        def execute
          if @main_args.include?('-h') || @main_args.include?('--help')
            # Print the help for all the linode commands.
            return help
          end

          command_class = @subcommands.get(@sub_command.to_sym) if @sub_command
          return help if !command_class || !@sub_command
          @logger.debug("Invoking command class: #{command_class} #{@sub_args.inspect}")

          # Initialize and execute the command class
          command_class.new(@sub_args, @env).execute
        end

        def help
          opts = OptionParser.new do |opts|
            opts.banner = 'Usage: vagrant linode <subcommand> [<args>]'
            opts.separator ''
            opts.separator 'Available subcommands:'

            # Add the available subcommands as separators in order to print them
            # out as well.
            keys = []
            @subcommands.each { |key, _value| keys << key.to_s }

            keys.sort.each do |key|
              opts.separator "     #{key}"
            end

            opts.separator ''
            opts.separator 'For help on any individual subcommand run `vagrant linode <subcommand> -h`'
          end

          @env.ui.info(opts.help, prefix: false)
        end
      end
    end
  end
end
