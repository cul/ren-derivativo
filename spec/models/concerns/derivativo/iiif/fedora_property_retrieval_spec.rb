require 'rails_helper'

describe Derivativo::Iiif::FedoraPropertyRetrieval, type: :unit do
  let(:test_class) do
    _c = Class.new
    _c.send :include, Derivativo::Iiif::FedoraPropertyRetrieval
    _c
  end
  let(:image_pid) { 'test:1234' }
  let(:content_ds) { RDF::URI.new("info:fedora/#{image_pid}/content")}
  let(:original_image_width) { 1234 }
  let(:original_image_height) { 4231 }
  let(:upright_dims) { [original_image_width, original_image_height] }
  let(:rotated_dims) { [original_image_height, original_image_width] }
  let(:image_resource) do
    _i = GenericResource.new(pid: image_pid)
    _i.rels_int.tap do |graph|
      graph.add_relationship(content_ds, :image_width, original_image_width.to_s, true)
      graph.add_relationship(content_ds, :image_length, original_image_height.to_s, true)
    end
    _i.add_datastream(_i.create_datastream(ActiveFedora::Datastream, "content"))
    _i
  end
  let(:test_obj) { test_class.new }
  before do
    test_obj.instance_variable_set(:@representative_generic_resource, image_resource)
  end
  subject { test_obj.fedora_get_original_image_dimensions }
  context "rotated 0" do
    before { image_resource.orientation = 0 }
    it "has unaltered dimensions array" do
      is_expected.to eql(upright_dims)
    end
  end
  context "rotated 90" do
    before { image_resource.orientation = 90 }
    it "has rotated dimensions array" do
      is_expected.to eql(rotated_dims)
    end
  end
  context "rotated 180" do
    before { image_resource.orientation = 180 }
    it "has unaltered dimensions array" do
      is_expected.to eql(upright_dims)
    end
  end
  context "rotated 270" do
    before { image_resource.orientation = 270 }
    it "has rotated dimensions array" do
      is_expected.to eql(rotated_dims)
    end
  end
  context "closed" do
    before { allow(image_resource).to receive(:closed?).and_return(true) }
    it { expect(test_obj.fedora_get_representative_generic_resource_closed).to be true }
  end
  context "restricted image" do
    before { allow(image_resource).to receive(:access_levels).and_return(["Embargoed"]) }
    it { expect(test_obj.fedora_get_is_restricted_size_image).to be true }
  end
  context "public image" do
    before { allow(image_resource).to receive(:access_levels).and_return(["Public Access"]) }
    it { expect(test_obj.fedora_get_is_restricted_size_image).to be false }
  end
end