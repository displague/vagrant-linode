require 'spec_helper'
require 'vagrant-linode/config'

describe VagrantPlugins::Linode::Config do
  describe 'defaults' do
    let(:vagrant_public_key) { Vagrant.source_root.join('keys/vagrant.pub') }

    subject do
      super().tap(&:finalize!)
    end

    its(:api_key)  { should be_nil }
    its(:api_url)  { should be_nil }
    its(:distribution) { should eq(/Ubuntu/) }
    its(:datacenter) { should eq(/dallas/) }
    its(:plan) { should eq(/1024/) }
    its(:paymentterm)   { should eq(/1/) }
    its(:private_networking)    { should eq(/Ubuntu/) }
    its(:ca_path) { should eql(vagrant_public_key) }
    its(:ssh_key_name) { should eq(/Vagrant/) }
    its(:setup) { should eq(true) }
    its(:xvda_size) { should eq(true) }
    its(:swap_size) { should eq(256) }
  end

  describe 'overriding defaults' do
    [:api_key,
     :api_url,
     :distribution,
     :plan,
     :paymentterm,
     :private_networking,
     :ca_path,
     :ssh_key_name,
     :setup,
     :xvda_size,
     :swap_size].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, 'foo')
        subject.finalize!
        subject.send(attribute).should == 'foo'
      end
    end

    it 'should not default plan if overridden' do
      plan = 'Linode 2048'
      subject.send(:plan, plan)
      subject.finalize!
      subject.send(:plan).should include(plan)
    end

  end

  describe 'validation' do
    let(:machine) { double('machine') }
    let(:validation_errors) { subject.validate(machine)['Linode Provider'] }
    let(:error_message) { double('error message') }

    before(:each) do
      machine.stub_chain(:env, :root_path).and_return '/'
      subject.api_key = 'bar'
    end

    subject do
      super().tap(&:finalize!)
    end

    context 'with invalid key' do
      it 'should raise an error' do
        subject.nonsense1 = true
        subject.nonsense2 = false
        I18n.should_receive(:t).with('vagrant.config.common.bad_field',
                                     fields: 'nonsense1, nonsense2')
        .and_return error_message
        validation_errors.first.should == error_message
      end
    end
    context 'with good values' do
      it 'should validate' do
        validation_errors.should be_empty
      end
    end

    context 'the API key' do
      it 'should error if not given' do
        subject.api_key = nil
        I18n.should_receive(:t).with('vagrant_linode.config.api_key').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'the public key path' do
      it "should have errors if the key doesn't exist" do
        subject.public_key_path = 'missing'
        I18n.should_receive(:t).with('vagrant_linode.config.public_key_not_found').and_return error_message
        validation_errors.first.should == error_message
      end
      it 'should not have errors if the key exists with an absolute path' do
        subject.public_key_path = File.expand_path 'locales/en.yml', Dir.pwd
        validation_errors.should be_empty
      end
      it 'should not have errors if the key exists with a relative path' do
        machine.stub_chain(:env, :root_path).and_return '.'
        subject.public_key_path = 'locales/en.yml'
        validation_errors.should be_empty
      end
    end

    context 'the username' do
      it 'should error if not given' do
        subject.username = nil
        I18n.should_receive(:t).with('vagrant_linode.config.username_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    [:linode_compute_url, :linode_auth_url].each do |url|
      context "the #{url}" do
        it 'should not validate if the URL is invalid' do
          subject.send "#{url}=", 'baz'
          I18n.should_receive(:t).with('vagrant_linode.config.invalid_uri', key: url, uri: 'baz').and_return error_message
          validation_errors.first.should == error_message
        end
      end
    end
  end

  describe 'linode_auth_url' do
    it 'should return UNSET_VALUE if linode_auth_url and linode_region are UNSET' do
      subject.linode_auth_url.should == VagrantPlugins::Linode::Config::UNSET_VALUE
    end
    it 'should return UNSET_VALUE if linode_auth_url is UNSET and linode_region is :ord' do
      subject.linode_region = :ord
      subject.linode_auth_url.should == VagrantPlugins::Linode::Config::UNSET_VALUE
    end
    it 'should return UK Authentication endpoint if linode_auth_url is UNSET and linode_region is :lon' do
      subject.linode_region = :lon
      subject.linode_auth_url.should == Fog::Linode::UK_AUTH_ENDPOINT
    end
    it 'should return custom endpoint if supplied and linode_region is :lon' do
      my_endpoint = 'http://custom-endpoint.com'
      subject.linode_region = :lon
      subject.linode_auth_url = my_endpoint
      subject.linode_auth_url.should == my_endpoint
    end
    it 'should return custom endpoint if supplied and linode_region is UNSET' do
      my_endpoint = 'http://custom-endpoint.com'
      subject.linode_auth_url = my_endpoint
      subject.linode_auth_url.should == my_endpoint
    end
  end

  describe 'lon_region?' do
    it 'should return false if linode_region is UNSET_VALUE' do
      subject.linode_region = VagrantPlugins::Linode::Config::UNSET_VALUE
      subject.send(:lon_region?).should be_false
    end
    it 'should return false if linode_region is nil' do
      subject.linode_region = nil
      subject.send(:lon_region?).should be_false
    end
    it 'should return false if linode_region is :ord' do
      subject.linode_region = :ord
      subject.send(:lon_region?).should be_false
    end
    it "should return true if linode_region is 'lon'" do
      subject.linode_region = 'lon'
      subject.send(:lon_region?).should be_true
    end
    it 'should return true if linode_Region is :lon' do
      subject.linode_region = :lon
      subject.send(:lon_region?).should be_true
    end
  end

  describe 'network' do
    it 'should remove SERVICE_NET_ID if :service_net is detached' do
      subject.send(:network, :service_net, attached: false)
      subject.send(:networks).should_not include(VagrantPlugins::Linode::Config::SERVICE_NET_ID)
    end

    it 'should not allow duplicate networks' do
      net_id = 'deadbeef-0000-0000-0000-000000000000'
      subject.send(:network, net_id)
      subject.send(:network, net_id)
      subject.send(:networks).count(net_id).should == 1
    end
  end
end
