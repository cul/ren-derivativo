# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::Conversion::FfmpegHelpers do
  let(:src_file_path) { file_fixture('video.mp4').realpath.to_s }
  let(:ffmpeg_input_args) { '-threads 1' }
  let(:ffmpeg_output_args) { '-threads 1 -vn -c:a aac -b:a 128k -ar 48000 -ac 2 -af aresample=async=1:min_hard_comp=0.100000:first_pts=0' }

  describe '.ffmpeg_convert' do
    it 'works as expected' do
      with_auto_deleting_tempfile('dst', '.mp4') do |dst_file|
        described_class.ffmpeg_convert(src_file_path: src_file_path, dst_file_path: dst_file.path, ffmpeg_input_args: ffmpeg_input_args, ffmpeg_output_args: ffmpeg_output_args)
        expect(File.size(dst_file.path)).to be_positive
      end
    end
  end

  describe '.ffmpeg_video_screenshot' do
    it 'works as expected' do
      with_auto_deleting_tempfile('dst', '.png') do |dst_file|
        described_class.ffmpeg_video_screenshot(src_file_path: src_file_path, dst_file_path: dst_file.path)
        expect(File.size(dst_file.path)).to be_positive
      end
    end
  end

  describe '.ffmppeg_input_args_string_as_hash' do
    let(:ffmpeg_input_args) { '-threads 1 -something1 value1 -something2 value2 -otherthing -something3 value3 -yetanotherthing' }
    let(:expected_hash_args) { { 'threads' => '1', 'something1' => 'value1', 'something2' => 'value2', 'otherthing' => nil, 'something3' => 'value3', 'yetanotherthing' => nil } }

    it 'works as expected' do
      expect(described_class.ffmppeg_input_args_string_as_hash(ffmpeg_input_args)).to eq(expected_hash_args)
    end
  end
end
