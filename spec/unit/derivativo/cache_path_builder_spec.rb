require 'rails_helper'

describe Derivativo::CachePathBuilder do

  let(:cache_base_directory) { File.join(Rails.root, 'tmp', 'base') }
  let(:cache_iiif_directory) { File.join(Rails.root, 'tmp', 'iiif') }
  let(:cache_path_builder_opts) { {
    cache_base_directory: cache_base_directory,
    cache_iiif_directory: cache_iiif_directory
  } }
  let(:digest) { Digest::SHA256.hexdigest(asset_id) }
  let(:cache_path_builder) do
    Derivativo::CachePathBuilder.factory(cache_path_builder_opts, true)
  end

  context "#base_path_for_id" do
    context "should return the expected cache path directory for the supplied params" do
      let(:asset_id) { 'abc:123' }
      it do
        expected = File.join(cache_path_builder_opts[:cache_base_directory], digest[0..1], digest[2..3], digest[4..5], digest)
        expect(cache_path_builder.base_path_for_id(asset_id)).to eql expected
      end
    end

    context "should return the expected cache path directory within the placeholder directory when the supplied image id starts with 'placeholder:'" do
      let(:placeholder_type) { 'file' }
      let(:asset_id) { 'placeholder:' + placeholder_type }
      it do
        expected = File.join(cache_path_builder_opts[:cache_base_directory], 'placeholder', placeholder_type)
        expect(cache_path_builder.base_path_for_id(asset_id)).to eql expected
      end
    end
  end

  context "#iiif_path_for_id" do
    context "should return the expected cache path directory for the supplied params" do
      context "should return the expected cache path directory for the supplied params" do
        let(:asset_id) { 'abc:123' }
        it do
          expected = File.join(cache_path_builder_opts[:cache_iiif_directory], digest[0..1], digest[2..3], digest[4..5], digest)
          expect(cache_path_builder.iiif_path_for_id(asset_id)).to eql expected
        end
      end

      context "should return the expected cache path directory within the placeholder directory when the supplied image id starts with 'placeholder:'" do
        let(:placeholder_type) { 'file' }
        let(:asset_id) { 'placeholder:' + placeholder_type }
        it do
          expected = File.join(cache_path_builder_opts[:cache_iiif_directory], 'placeholder', placeholder_type)
          expect(cache_path_builder.iiif_path_for_id(asset_id)).to eql expected
        end
      end
    end
  end

  context "#media_path_for_id" do
    context "should return the expected cache path directory for the supplied params" do
      let(:asset_id) { 'abc:123' }
      let(:expected) {
        File.join(DERIVATIVO['cache_path'][restricted ? 'restricted' : 'public'][media_type], digest[0..1], digest[2..3], digest[4..5], digest)
      }

      context "public audio" do
        let(:restricted) { false }
        let(:media_type) { 'audio' }
        it do
          expect(cache_path_builder.media_path_for_id(media_type, restricted, asset_id)).to eql expected
        end
      end

      context "restricted audio" do
        let(:restricted) { true }
        let(:media_type) { 'audio' }
        it do
          expect(cache_path_builder.media_path_for_id(media_type, restricted, asset_id)).to eql expected
        end
      end

      context "public video" do
        let(:restricted) { false }
        let(:media_type) { 'video' }
        it do
          expect(cache_path_builder.media_path_for_id(media_type, restricted, asset_id)).to eql expected
        end
      end

      context "restricted video" do
        let(:restricted) { true }
        let(:media_type) { 'video' }
        it do
          expect(cache_path_builder.media_path_for_id(media_type, restricted, asset_id)).to eql expected
        end
      end

    end
  end

end
