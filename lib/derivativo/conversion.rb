# frozen_string_literal: true

require 'benchmark'

module Derivativo
  module Conversion
    def self.image_to_image(src_file_path:, dst_file_path:, rotation: 0, size: nil)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        Imogen.with_image(src_file_path) do |img|
          Imogen::Iiif.convert(
            img,
            dst_file_path,
            File.extname(dst_file_path).delete_prefix('.'),
            region: 'full',
            size: size ? "!#{size},#{size}" : 'full',
            rotation: rotation,
            quality: 'color'
          )
        end
      end
    end

    def self.video_to_video(src_file_path:, dst_file_path:, ffmpeg_input_args:, ffmpeg_output_args:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        FfmpegHelpers.ffmpeg_convert(
          src_file_path: src_file_path, dst_file_path: dst_file_path,
          ffmpeg_input_args: ffmpeg_input_args, ffmpeg_output_args: ffmpeg_output_args
        )
      end
    end

    def self.video_to_image(src_file_path:, dst_file_path:, size: nil)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        FfmpegHelpers.ffmpeg_video_screenshot(src_file_path: src_file_path, dst_file_path: dst_file_path, size: size)
      end
    end

    def self.audio_to_audio(src_file_path:, dst_file_path:, ffmpeg_input_args:, ffmpeg_output_args:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        FfmpegHelpers.ffmpeg_convert(
          src_file_path: src_file_path, dst_file_path: dst_file_path,
          ffmpeg_input_args: ffmpeg_input_args, ffmpeg_output_args: ffmpeg_output_args
        )
      end
    end

    def self.pdf_to_pdf(src_file_path:, dst_file_path:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        GhostscriptHelpers.ghostscript_convert_pdf_to_pdf(
          src_file_path: src_file_path, dst_file_path: dst_file_path
        )
      end
    end

    def self.pdf_to_image(src_file_path:, dst_file_path:, size:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        # Ghostscript will convert the PDF to an image, but we don't have a great way of specifying
        # an exact size for that PDF.  So we'll create the image first in a temporary file, and then
        # we'll convert that image to the desired size.
        Derivativo::FileHelper.working_directory_temp_file('pdf-as-image', '.png') do |tempfile|
          GhostscriptHelpers.ghostscript_pdf_to_image(src_file_path: src_file_path, dst_file_path: tempfile.path)
          image_to_image(src_file_path: tempfile.path, dst_file_path: dst_file_path, size: size)
        end
      end
    end

    def self.text_or_office_document_to_pdf(src_file_path:, dst_file_path:)
      with_logged_timing(__callee__, src_file_path, dst_file_path) do
        OfficeHelpers.office_convert_to_pdf(src_file_path: src_file_path, dst_file_path: dst_file_path)
      end
    end

    def self.with_logged_timing(method_name, src_file_path, dst_file_path)
      Rails.logger.debug "#{method_name} converting #{src_file_path} ..."
      time = Benchmark.measure do
        yield
      end
      Rails.logger.debug("#{method_name} finished converting #{src_file_path} to #{dst_file_path} in #{time.real} seconds.")
    end
  end
end
