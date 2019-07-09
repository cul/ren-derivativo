require 'rails_helper'

describe Derivativo::Iiif::CachableProperties, type: :unit do
  let(:test_class) do
    _c = Class.new do
      include Derivativo::Iiif::FedoraPropertyRetrieval
      include Derivativo::Iiif::CachableProperties

      attr_accessor :id

      def initialize(id)
        @id = id
      end
      # dummy methods because of unseparated concerns
      def db_cache_has?(key)
        false
      end
      def db_cache_set(key, val)
        val
      end
    end
    #_c.send :include, Derivativo::Iiif::FedoraPropertyRetrieval
    #_c.send :include, Derivativo::Iiif::CachableProperties
    #_c
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
  let(:test_obj) { test_class.new(image_pid) }
  before do
    test_obj.instance_variable_set(:@representative_generic_resource, image_resource)
  end
  context "closed" do
    before { allow(image_resource).to receive(:closed?).and_return(true) }
    it { expect(test_obj.has_placeholder_image?).to be true }
    it { expect(test_obj.send :placeholder_image_type).to be Derivativo::Iiif::CacheKeys::DC_TYPES_TO_PLACEHOLDER_TYPES['Closed'] }
  end
end