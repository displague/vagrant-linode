require 'fog'
require 'aruba/cucumber'

Fog.mock! if ENV['LINODE_MOCK'] == 'true'

Before do | scenario |
  @aruba_timeout_seconds = 600
  @scenario = File.basename(scenario.file)
  ENV['CASSETTE'] = @scenario

  proxy_options = {
    connection_options: {
      proxy: ENV['https_proxy'],
      ssl_verify_peer: false
    }
  }

  connect_options = {
    provider: 'linode',
    linode_username: ENV['LINODE_USERNAME'],
    linode_api_key: ENV['LINODE_API_KEY'],
    version: :v2, # Use Next Gen Cloud Servers
    linode_region: ENV['LINODE_REGION'].downcase.to_sym
  }
  connect_options.merge!(proxy_options) unless ENV['https_proxy'].nil?
  @compute = Fog::Compute.new(connect_options)
end

Around do | _scenario, block |
  Bundler.with_clean_env do
    block.call
  end
end

After('@creates_server') do
  @compute.servers.delete @server_id
end
