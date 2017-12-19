require "vagrant-linode/services/volume_manager"

describe VagrantPlugins::Linode::Services::VolumeManager do
  subject { described_class.new(machine, client, logger) }
  let(:provider_config) { double(:config, volumes: [{label: "testvolume", size: 3}]) }
  let(:machine) { double(:machine, id: 123, name: "test", provider_config: provider_config) }
  let(:logger) { double(:logger, info: nil) }
  let(:remote_volumes) { [double(:volume, volumeid: 234, size: 3, label: "test_testvolume")] }
  let(:client) { double(:api, list: remote_volumes) }

  describe "#perform" do
    context "when the volume label is not specified" do
      let(:provider_config) { double(:config, volumes: [{size: 3}]) }
      it "raises an error" do
        expect { subject.perform }.to raise_error "You must specify a volume label."
      end
    end

    context "when the remote volume does not exist" do
      let(:remote_volumes) { [] }
      it "creates the volume bound to the linode" do
        expect(client).to receive(:create).with(label: "test_testvolume", size: 3, linodeid: 123)
        subject.perform
      end

      context "when the size is not specified" do
        let(:provider_config) { double(:config, volumes: [{label: "testvolume"}]) }
        it "raises an error" do
          expect { subject.perform }.to raise_error "For volumes that need to be created the size has to be specified."
        end
      end
    end

    context "when the remote volume exists" do
      let(:remote_volumes) { [double(:volume, volumeid: 234, size: 3, label: "test_testvolume")] }
      it "attaches the volume to the machine" do
        expect(client).to receive(:update).with(volumeid: 234, linodeid: 123)
        subject.perform
      end
    end
  end
end
