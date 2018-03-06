# frozen_string_literal: true

require "keycard/institution_finder"
require "sequel_helper"
require "ipaddr"

RSpec.describe Keycard::InstitutionFinder, DB: true do
  subject { described_class.new }

  describe "#attributes_for" do
    let(:request) { double(:request) }

    def add_inst_network(inst:, network:, access:)
      @unique_id ||= 0
      @unique_id += 1
      range = IPAddr.new(network).to_range
      Keycard::DB[:aa_network].insert([@unique_id, nil, network, range.first.to_i, range.last.to_i,
                                       access.to_s, nil, inst, Time.now.utc, 'test', 'f'])
    end

    before(:each) do
      add_inst_network(inst: 1, network: '10.0.0.0/16', access: :allow)
      add_inst_network(inst: 1, network: '10.0.2.0/24', access: :deny)

      # range in two institutions
      add_inst_network(inst: 2, network: '10.0.1.0/24', access: :allow)

      # denied from one, allowed to another
      add_inst_network(inst: 1, network: '10.0.3.0/24', access: :deny)
      add_inst_network(inst: 2, network: '10.0.3.0/24', access: :allow)

      allow(request).to receive(:get_header)
        .with('X-Forwarded-For')
        .and_return(client_ip)
    end

    subject { described_class.new(db: Keycard::DB.db).attributes_for(request) }

    context "with an ip with a single institution" do
      let(:client_ip) { "10.0.0.1" }

      it "returns a hash with (only) a dlpsInstitutionIds key" do
        expect(subject.keys).to contain_exactly('dlpsInstitutionIds')
      end

      it "returns the correct institution" do
        expect(subject['dlpsInstitutionIds']).to contain_exactly(1)
      end
    end

    context "with an ip with multiple institutions" do
      let(:client_ip) { "10.0.1.1" }
      it "returns the set of institutions" do
        expect(subject['dlpsInstitutionIds']).to contain_exactly(1, 2)
      end
    end

    context "with an IP address allowed and denied in the same institituion" do
      let(:client_ip) { "10.0.2.1" }
      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "with an IP address allowed in two insts and denied in one of them" do
      let(:client_ip) { "10.0.3.1" }
      it "returns the institution it wasn't denied from" do
        expect(subject['dlpsInstitutionIds']).to contain_exactly(2)
      end
    end

    context "with an ip address not in any ranges" do
      let(:client_ip) { "192.168.0.1" }
      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "with an invalid IP address" do
      let(:client_ip) { "10.0.324.456" }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "with no ip" do
      let(:client_ip) { nil }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end
  end
end