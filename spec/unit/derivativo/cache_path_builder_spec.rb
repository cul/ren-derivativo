require 'rails_helper'

describe Derivativo::CachePathBuilder do

  let(:cache_root) { File.join(Rails.root, 'spec', 'fixtures') }
  let(:cache_path_builder_opts) { {cache_directory: cache_root} }
  let(:digest) { Digest::SHA256.hexdigest(image_id) }
  let(:cache_path_builder) do
    Derivativo::CachePathBuilder.factory(cache_path_builder_opts, true)   
  end
  
  context "#path_for_id" do
    context "should return the expected cache path directory for the supplied params" do
      let(:image_id) { 'abc:123' }
      it do
        digest = Digest::SHA256.hexdigest(image_id)
        expected = File.join(cache_path_builder_opts[:cache_directory], digest[0..1], digest[2..3], digest[4..5], digest)
        expect(cache_path_builder.path_for_id(image_id)).to eql expected
      end
    end
    
    context "should return the expected cache path directory within the placeholder directory when the supplied image id starts with 'placeholder:'" do
      let(:placeholder_type) { 'file' }
      let(:image_id) { 'placeholder:' + placeholder_type }
      it do
        expected = File.join(cache_path_builder_opts[:cache_directory], 'placeholder', placeholder_type)
        expect(cache_path_builder.path_for_id(image_id)).to eql expected
      end
    end
  end
  
  context "#path_for_type" do
    context "iiif type" do
      let(:image_id) { 'abc:123' }
      let(:type) { ':iiif' }
      it do
        digest = Digest::SHA256.hexdigest(image_id)
        expected = File.join(cache_path_builder_opts[:cache_directory], digest[0..1], digest[2..3], digest[4..5], digest, 'iiif')
        expect(cache_path_builder.path_for_type(image_id, Derivativo::CachePathBuilder::TYPE_IIIF)).to eql expected
      end
    end
  end
  
end
