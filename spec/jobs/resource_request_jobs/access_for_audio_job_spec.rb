# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceRequestJobs::AccessForAudioJob do
  let(:instance) { described_class.new }

  let(:resource_request_id) { 1 }
  let(:digital_object_uid) { '123-456-789' }
  let(:src_file_location) { "file://#{file_fixture('audio.wav').realpath}" }
  let(:options) do
    {
      'format' => 'm4a',
      'ffmpeg_input_args' => '-threads 1',
      'ffmpeg_output_args' => '-threads 1 -vn -c:a aac -b:a 128k -ar 48000 -ac 2 -af aresample=async=1:min_hard_comp=0.100000:first_pts=0'
    }
  end
  let(:perform_args) do
    {
      resource_request_id: resource_request_id,
      digital_object_uid: digital_object_uid,
      src_file_location: src_file_location,
      options: options
    }
  end

  describe '#perform' do
    before do
      expect(Hyacinth::Client.instance).to receive(:resource_request_in_progress!).with(resource_request_id)
      expect(Hyacinth::Client.instance).to receive(:upload_file_to_active_storage).with(/#{'working_directory'}.+/, 'access.m4a').and_return('some-signed-id')
      expect(Hyacinth::Client.instance).to receive(:create_resource).with(digital_object_uid, 'access', 'blob://some-signed-id')
      expect(Hyacinth::Client.instance).to receive(:resource_request_success!).with(resource_request_id)
    end
    it 'works as expected when valid arguments are given' do
      expect(instance.perform(perform_args))
    end
  end
end
