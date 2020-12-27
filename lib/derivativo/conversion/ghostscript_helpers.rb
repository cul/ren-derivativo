# frozen_string_literal: true

module Derivativo
  module Conversion
    module GhostscriptHelpers
      # Converts an input pdf file to an output pdf file
      def self.ghostscript_convert_pdf_to_pdf(src_file_path:, dst_file_path:)
        _stdout_str, stderr_str, _status = Open3.capture3(
          pdf_to_pdf_conversion_command(
            DERIVATIVO['ghostscript_binary_path'] || Derivativo::UserPathHelper.which('gs'),
            src_file_path,
            dst_file_path
          )
        )

        # We don't expect to get error output, so if any appears we want to send it to the log.
        Rails.logger.error("Ghostscript (convert) stderr: #{stderr_str}") if stderr_str.present?

        Derivativo::FileHelper.block_until_file_exists(dst_file_path)
      end

      def self.ghostscript_pdf_to_image(src_file_path:, dst_file_path:)
        _stdout_str, stderr_str, _status = Open3.capture3(
          pdf_to_image_conversion_command(
            DERIVATIVO['ghostscript_binary_path'] || Derivativo::UserPathHelper.which('gs'),
            src_file_path,
            dst_file_path
          )
        )

        # We don't expect to get error output, so if any appears we want to send it to the log.
        Rails.logger.error("Ghostscript (pdf_to_image) stderr: #{stderr_str}") if stderr_str.present?

        Derivativo::FileHelper.block_until_file_exists(dst_file_path)
      end

      def self.pdf_to_pdf_conversion_command(ghostscript_binary_path, src_file_path, dst_file_path)
        [
          ghostscript_binary_path,
          '-q', '-dNOPAUSE', '-dBATCH', '-dPrinted=false', '-dSAFER', '-dQUIET',
          '-dCompatibilityLevel=1.4', '-dSimulateOverprint=true', '-sDEVICE=pdfwrite', '-dPDFSETTINGS=/screen',
          '-dEmbedAllFonts=true', '-dSubsetFonts=true', '-dAutoRotatePages=/None', '-dColorImageDownsampleType=/Bicubic',
          '-dColorImageResolution=150', '-dGrayImageDownsampleType=/Bicubic', '-dGrayImageResolution=150', '-dMonoImageDownsampleType=/Bicubic', '-dMonoImageResolution=150'
        ].concat(ghostscript_pdf_to_pdf_version_specific_args(ghostscript_binary_path)).concat(
          [
            "-sOutputFile=#{Shellwords.escape(dst_file_path)}",
            Shellwords.escape(src_file_path)
          ]
        ).join(' ')
      end

      def self.ghostscript_pdf_to_pdf_version_specific_args(ghostscript_binary_path)
        stdout, _status = Open3.capture2("#{ghostscript_binary_path} --version")
        ver = stdout.match('(\d+)\.')[1].to_i
        if ver < 9
          ['-dUseCIEColor', '-sColorConversionStrategy=UseDeviceIndependentColor']
        else
          ['-dPDFA=2', '-dPDFACompatibilityPolicy=1']
        end
      end

      def self.pdf_to_image_conversion_command(ghostscript_binary_path, src_file_path, dst_file_path)
        [
          ghostscript_binary_path,
          '-dNOPAUSE',
          "-sDEVICE=#{dst_file_path.ends_with?('.jpg') ? 'jpeg' : 'png16m'}",
          '-dTextAlphaBits=4',
          '-dGraphicsAlphaBits=4',
          '-r300'
          # First page and last page params aren't necessary if we're always doing the first page,
          # but this is how we would select a different page (if we want to in the future):
          # '-dFirstPage=1',
          # '-dLastPage=1'
        ].concat(
          [
            "-sOutputFile=#{Shellwords.escape(dst_file_path)}",
            Shellwords.escape(src_file_path)
          ]
        ).join(' ')
      end
    end
  end
end
