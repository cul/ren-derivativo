# frozen_string_literal: true

require 'benchmark'

module Derivativo
  module Conversion
    def self.image_to_image(src_file_path:, dst_file_path:, rotation: '0')
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        Imogen.with_image(src_file_path) do |img|
          Imogen::Iiif.convert(
            img,
            dst_file_path,
            File.extname(dst_file_path).delete_prefix('.'),
            region: 'full',
            size: 'full',
            rotation: rotation,
            quality: 'color'
          )
        end
      end
    end

    def self.video_to_video(src_file_path:, dst_file_path:, ffmpeg_input_args:, ffmpeg_output_args:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        FfmpegHelpers.ffmpeg_convert(src_file_path: src_file_path, dst_file_path: dst_file_path, ffmpeg_input_args: ffmpeg_input_args, ffmpeg_output_args: ffmpeg_output_args)
      end
    end

    def self.video_to_image(src_file_path:, dst_file_path:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        FfmpegHelpers.ffmpeg_video_screenshot(src_file_path: src_file_path, dst_file_path: dst_file_path)
      end
    end

    def self.audio_to_audio(src_file_path:, dst_file_path:, ffmpeg_input_args:, ffmpeg_output_args:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        FfmpegHelpers.ffmpeg_convert(src_file_path: src_file_path, dst_file_path: dst_file_path, ffmpeg_input_args: ffmpeg_input_args, ffmpeg_output_args: ffmpeg_output_args)
      end
    end

    def self.pdf_to_pdf(src_file_path:, dst_file_path:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        GhostscriptHelpers.ghostscript_convert_pdf_to_pdf(src_file_path: src_file_path, dst_file_path: dst_file_path)
      end
    end

    def self.pdf_to_image(src_file_path:, dst_file_path:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        GhostscriptHelpers.ghostscript_pdf_to_image(src_file_path: src_file_path, dst_file_path: dst_file_path)
      end
    end

    def self.text_or_office_document_to_pdf(src_file_path:, dst_file_path:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        OfficeHelpers.office_convert_to_pdf(src_file_path: src_file_path, dst_file_path: dst_file_path)
      end
    end

    def self.with_logged_timing(method_name, src_file_path, dst_file_path)
      Rails.logger.info "#{method_name} converting #{src_file_path} ..."
      time = Benchmark.measure do
        yield
      end
      Rails.logger.info("#{method_name} finished converting #{src_file_path} to #{dst_file_path} in #{time.real} seconds.")
    end
  end
end
