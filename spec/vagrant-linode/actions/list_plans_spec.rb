require 'spec_helper'
require 'vagrant-linode/actions/list_plans'

describe VagrantPlugins::Linode::Actions::ListPlans do
  let(:app) { lambda { |_env| } }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:plans) do
    Fog.mock!
    Fog::Compute.new(provider: :linode,
                     linode_datacenter: :dallas,
                     linode_api_key: 'anything',
                     linode_username: 'anything').plans
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
    allow(compute_connection).to receive(:plans).and_return plans
  end

  it 'get plans from Fog' do
    expect(compute_connection).to receive(:plans).and_return plans
    action.call(env)
  end

  it 'writes a sorted, formatted plan table to Vagrant::UI' do
    header_line = '%-36s %s' % ['Plan ID', 'Plan Name']
    expect(ui).to receive(:info).with(header_line)
    plans.sort_by(&:id).each do |plan|
      formatted_line = '%-36s %s' % [plan.id, plan.name]
      expect(ui).to receive(:info).with formatted_line
    end
    action.call(env)
  end

  it 'continues the middleware chain' do
    expect(app).to receive(:call).with(env)
    action.call(env)
  end
end
