# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceRequestJobs::FeaturedThumbnailRegionJob do
  let(:instance) { described_class.new }

  let(:resource_request_id) { 1 }
  let(:digital_object_uid) { '123-456-789' }
  let(:src_file_location) { "file://#{file_fixture('image.jpg').realpath}" }
  let(:options) { {} }
  let(:perform_args) do
    {
      resource_request_id: resource_request_id,
      digital_object_uid: digital_object_uid,
      src_file_location: src_file_location,
      options: options
    }
  end
  let(:expected_featured_region) { '213,413,853,853' }

  describe '#perform' do
    before do
      # Stub the featured_thumbnail_region method so that we get a consistent value back for testing
      allow(Derivativo::ImageAnalysis).to receive(:featured_thumbnail_region).and_return(expected_featured_region)

      expect(Hyacinth::Client.instance).to receive(:resource_request_in_progress!).with(resource_request_id)
      expect(Hyacinth::Client.instance).to receive(:update_featured_thumbnail_region).with(digital_object_uid, expected_featured_region)
      expect(Hyacinth::Client.instance).to receive(:resource_request_success!).with(resource_request_id)
    end
    it 'works as expected when valid arguments are given' do
      expect(instance.perform(**perform_args))
    end
  end
end
