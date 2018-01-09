require 'rails_helper'

describe Manifest do
  let(:doi) { '10.abc/123' }
  let(:route_helper) { double('routes') }
  let(:routing_opts) { Hash.new }
  let(:xml) { "<structMap xmlns=\"http://www.loc.gov/METS/\"></structMap>" }
  before do
    allow(route_helper).to receive(:iiif_manifest_url).and_return("info://manifest/#{doi}/manifest")
  end
  it "creates a hash from xml" do
    expect(Manifest.struct_map_to_h(xml, route_helper, routing_opts)).to be_a Hash
  end
end