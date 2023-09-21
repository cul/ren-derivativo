# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::Conversion do
  describe '.image_to_image' do
    let(:src_file_path) { file_fixture('image.jpg').realpath.to_s }

    it 'works as expected' do
      with_auto_deleting_tempfile('dst', '.png') do |dst_file|
        expect(Imogen::Iiif).to receive(:convert).with(
          Vips::Image, dst_file.path, 'png',
          region: 'full',
          size: 'full',
          rotation: 0,
          quality: 'color'
        )
        described_class.image_to_image(src_file_path: src_file_path, dst_file_path: dst_file.path)
      end
    end

    it 'works as expected when the optional rotation and size keyword args are given' do
      with_auto_deleting_tempfile('dst', '.png') do |dst_file|
        expect(Imogen::Iiif).to receive(:convert).with(
          Vips::Image, dst_file.path, 'png',
          region: 'full',
          size: '!500,500',
          rotation: '90',
          quality: 'color'
        )
        described_class.image_to_image(src_file_path: src_file_path, dst_file_path: dst_file.path, rotation: '90', size: 500)
      end
    end
  end

  describe '.video_to_video' do
    let(:args) do
      {
        src_file_path: '/path/to/src',
        dst_file_path: '/path/to/dst',
        ffmpeg_input_args: '-input-arg',
        ffmpeg_output_args: '-output-arg'
      }
    end

    it 'works as expected' do
      expect(Derivativo::Conversion::FfmpegHelpers).to receive(:ffmpeg_convert).with(args)
      described_class.video_to_video(**args)
    end
  end

  describe '.video_to_image' do
    let(:args) do
      {
        src_file_path: '/path/to/src',
        dst_file_path: '/path/to/dst',
        size: 500
      }
    end

    it 'works as expected' do
      expect(Derivativo::Conversion::FfmpegHelpers).to receive(:ffmpeg_video_screenshot).with(args)
      described_class.video_to_image(**args)
    end
  end

  describe '.audio_to_audio' do
    let(:args) do
      {
        src_file_path: '/path/to/src',
        dst_file_path: '/path/to/dst',
        ffmpeg_input_args: '-input-arg',
        ffmpeg_output_args: '-output-arg'
      }
    end

    it 'works as expected' do
      expect(Derivativo::Conversion::FfmpegHelpers).to receive(:ffmpeg_convert).with(args)
      described_class.audio_to_audio(**args)
    end
  end

  describe '.pdf_to_pdf' do
    let(:args) do
      {
        src_file_path: '/path/to/src',
        dst_file_path: '/path/to/dst'
      }
    end

    it 'works as expected' do
      expect(Derivativo::Conversion::GhostscriptHelpers).to receive(:ghostscript_convert_pdf_to_pdf).with(args)
      described_class.pdf_to_pdf(**args)
    end
  end

  describe '.pdf_to_image' do
    let(:args) do
      {
        src_file_path: '/path/to/src',
        dst_file_path: '/path/to/dst',
        size: 500
      }
    end

    it 'works as expected' do
      expect(Derivativo::Conversion::GhostscriptHelpers).to receive(:ghostscript_pdf_to_image).with(
        src_file_path: args[:src_file_path], dst_file_path: String
      )
      expect(described_class).to receive(:image_to_image).with(
        src_file_path: String, dst_file_path: args[:dst_file_path], size: args[:size]
      )
      described_class.pdf_to_image(**args)
    end
  end

  describe '.text_or_office_document_to_pdf' do
    let(:args) do
      {
        src_file_path: '/path/to/src',
        dst_file_path: '/path/to/dst'
      }
    end

    it 'works as expected' do
      expect(Derivativo::Conversion::OfficeHelpers).to receive(:office_convert_to_pdf).with(args)
      described_class.text_or_office_document_to_pdf(**args)
    end
  end

  describe '.with_logged_timing' do
    let(:method_name) { 'some_method' }
    let(:src_file_path) { '/path/to/src' }
    let(:dst_file_path) { '/path/to/dst' }
    let(:fake_processing_time) { 1.2.seconds }
    let(:benchmark_time) { Benchmark::Tms.new(fake_processing_time, fake_processing_time, 0, 0, fake_processing_time) }

    before { allow(Benchmark).to receive(:measure).and_yield.and_return(benchmark_time) }

    it 'yields with no args' do
      expect { |b| described_class.with_logged_timing(method_name, src_file_path, dst_file_path, &b) }.to yield_with_no_args
    end

    it 'outputs the expected test to the Rails log' do
      expect(Rails.logger).to receive(:debug).with('some_method converting /path/to/src ...').ordered
      expect(Rails.logger).to receive(:debug).with(
        "some_method finished converting /path/to/src to /path/to/dst in #{fake_processing_time} seconds."
      ).ordered
      described_class.with_logged_timing(method_name, src_file_path, dst_file_path) {}
    end
  end
end
