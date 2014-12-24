require 'fog'
if ENV['LINODE_MOCK'] == 'true'
  Fog.mock!
  Fog::Linode::MockData.configure do |c|
    c[:image_name_generator] = proc { 'Ubuntu' }
    c[:ipv4_generator] = proc { '10.11.12.2' }
  end
  connect_options = {
    provider: 'linode',
    linode_username: ENV['LINODE_USERNAME'],
    linode_api_key: ENV['LINODE_API_KEY'],
    linode_region: :newark
  }
  connect_options.merge!(proxy_options) unless ENV['https_proxy'].nil?
  compute = Fog::Compute.new(connect_options)
  # Force creation of Ubuntu image so it will show up in compute.images.list
  compute.images.get(0)
end
