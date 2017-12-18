require 'rails_helper'

RSpec.describe IiifResource, type: :model do
  
  context "#initialize" do
    subject { described_class.new(opts) }
    
    context "initiaze with valid params" do
      let(:opts) do
        {id: 'some:id'}
      end
      it "sets expected default params" do
        expect(subject.id).to eql(opts[:id])
        expect(subject.version).to eql('2')
        expect(subject.region).to eql('full')
        expect(subject.size).to eql('full')
        expect(subject.rotation).to eql('0')
        expect(subject.quality).to eql('native')
        expect(subject.format).to eql('jpg')
      end
    end
    
    context "initiaze with valid params" do
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
    end
  end
  
end
