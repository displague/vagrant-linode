require 'spec_helper'
require 'vagrant-linode/action/list_distributions'

describe VagrantPlugins::Linode::Action::ListImages do
  let(:app) { lambda { |_env| } }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:distributions) do
    Fog.mock!
    Fog::Compute.new(provider: :linode,
                     linode_region: :dfw,
                     linode_api_key: 'anything',
                     linode_username: 'anything').distributions
  end
  let(:compute_connection) { double('fog connection') }
  let(:env) do
    {
      linode_compute: compute_connection,
      ui: ui
    }
  end

  subject(:action) { described_class.new(app, env) }

  before do
    allow(compute_connection).to receive(:distributions).and_return distributions
  end

  it 'get distributions from Fog' do
    expect(compute_connection).to receive(:distributions).and_return distributions
    action.call(env)
  end

  it 'writes a sorted, formatted image table to Vagrant::UI' do
    header_line = '%-36s %s' % ['Image ID', 'Image Name']
    expect(ui).to receive(:info).with(header_line)
    distributions.sort_by(&:name).each do |image|
      formatted_line = '%-36s %s' % [image.id.to_s, image.name]
      expect(ui).to receive(:info).with formatted_line
    end
    action.call(env)
  end

  it 'continues the middleware chain' do
    expect(app).to receive(:call).with(env)
    action.call(env)
  end
end
