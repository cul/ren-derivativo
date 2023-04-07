require 'rails_helper'

RSpec.describe IiifResource, type: :model do
  
  context "#initialize" do
    subject { described_class.new(opts) }
    
    context "initialize with valid params" do
      let(:well_known_pid) { 'some:id' }
      let(:resource_id) { well_known_pid }
      let(:opts) do
        {id: resource_id}
      end
      it "sets expected default params" do
        expect(subject.id).to eql(well_known_pid)
        expect(subject.version).to eql('2')
        expect(subject.region).to eql('full')
        expect(subject.size).to eql('full')
        expect(subject.rotation).to eql('0')
        expect(subject.quality).to eql('native')
        expect(subject.format).to eql('jpg')
      end
      context "with a fedora object id" do
        let(:resource_id) { ActiveFedora::Base.new(pid: well_known_pid) }
        it "sets expected default params" do
          expect(subject.id).to eql(well_known_pid)
          expect(subject.fedora_object).to be resource_id
          expect(subject.version).to eql('2')
          expect(subject.region).to eql('full')
          expect(subject.size).to eql('full')
          expect(subject.rotation).to eql('0')
          expect(subject.quality).to eql('native')
          expect(subject.format).to eql('jpg')
        end
      end
    end
    
    context "initialize with valid params" do
      let(:opts) do
        { id: 'example', version: '2', region: 'featured', size: '!100,200', rotation: '90', quality: 'gray', format: 'png' }
      end
      it "sets params properly" do
        expect(subject.id).to eql(opts[:id])
        expect(subject.version).to eql(opts[:version])
        expect(subject.region).to eql(opts[:region])
        expect(subject.size).to eql(opts[:size])
        expect(subject.rotation).to eql(opts[:rotation])
        expect(subject.quality).to eql(opts[:quality])
        expect(subject.format).to eql(opts[:format])
      end
      context "with a v3 size keyword, maps to v2" do
        subject { described_class.new(opts.merge(size: 'max')) }
        it "sets params properly" do
          expect(subject.id).to eql(opts[:id])
          expect(subject.size).to eql('full')
        end
      end
    end
  end
end
