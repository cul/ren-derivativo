# frozen_string_literal: true

module Derivativo
  module Conversion
    module OfficeHelpers
      PDF_HIGHER_COMPRESSION_CONVERSION_THRESHOLD = 30.megabytes

      SIZE_THRESHOLD_FOR_LARGE_OFFICE_CONVERSION_DOC_TIMEOUT = 5.megabytes
      SMALL_OFFICE_CONVERSION_DOC_TIMEOUT = 60.seconds
      LARGE_OFFICE_CONVERSION_DOC_TIMEOUT = 600.seconds # We need a long timeout for larger docs (like big CSV files)

      # Converts an input office output audiovisual file
      def self.office_convert_to_pdf(src_file_path:, dst_file_path:, first_page_only: false)
        office_convert_to_pdf_impl(
          src_file_path: src_file_path,
          dst_file_path: dst_file_path,
          soffice_binary_path: soffice_binary_path_from_config_or_path,
          first_page_only: first_page_only
        )

        # If the generated file size is less than or equal to our desired size, then we're done.
        generated_file_size = File.size(dst_file_path)
        return unless converted_file_size_merits_higher_compression_attempt?(generated_file_size)

        # If we got here, then the generated file is larger than our desired size.
        # We'll attempt one more conversion with higher compression.

        office_convert_to_pdf_impl(
          src_file_path: src_file_path,
          dst_file_path: dst_file_path,
          soffice_binary_path: soffice_binary_path_from_config_or_path,
          compression_integer: compression_value_for_first_try_file_size(generated_file_size),
          first_page_only: first_page_only
        )
      end

      def self.soffice_binary_path_from_config_or_path
        DERIVATIVO['soffice_binary_path'] || Derivativo::UserPathHelper.which('soffice')
      end

      def self.converted_file_size_merits_higher_compression_attempt?(file_size)
        # TODO: At some point, maybe change PDF_HIGHER_COMPRESSION_CONVERSION_THRESHOLD here into a configuration option instead
        # of a hard-coded value, though that will also change the logic in the
        # compression_value_for_first_try_file_size method.
        file_size > PDF_HIGHER_COMPRESSION_CONVERSION_THRESHOLD
      end

      def self.compression_value_for_first_try_file_size(size)
        return 80 if size <= PDF_HIGHER_COMPRESSION_CONVERSION_THRESHOLD

        # This formula seems to give decent results, but might need more adjustments in the future.
        ((1 / Math.log(size.to_f / 1.megabyte, 10))**2 * 100).to_i
      end

      def self.office_convert_to_pdf_impl(
        src_file_path:, dst_file_path:, soffice_binary_path:, compression_integer: 80, first_page_only: false
      )
        # Create a unique, temporary home dir for this office conversion process so we can run
        # multiple conversion jobs independently. If two conversion processes use the same
        # home dir, the first process will block the second one.
        Derivativo::FileHelper.working_directory_temp_dir('office_temp_homedir') do |office_temp_homedir|
          # Then write out an office settings file to set the desired PDF compression level.
          create_office_settings_file(office_temp_homedir.path, compression_integer)

          # Now we'll create a unique, temporary directory where we'll put our pre-renamed output file.
          # The office conversion process always keeps the original name of the file and replaces
          # the extension with 'pdf', so we'll need to predict the tmp outpath and move to the
          # expected dst_file_path after we're done with the conversion.
          Derivativo::FileHelper.working_directory_temp_dir('office_temp_outdir') do |office_temp_outdir|
            # Run conversion
            cmd_to_run = conversion_command(
              soffice_binary_path, src_file_path, office_temp_homedir.path,
              office_temp_outdir.path, first_page_only: first_page_only
            )
            _stdout, stderr = Derivativo::Utils::ShellUtils.run_with_timeout(
              cmd_to_run,
              conversion_timeout_for_src_file(src_file_path)
            )

            if stderr.present?
              raise Derivativo::Exceptions::ConversionError,
                    "Failed to convert document to PDF using command: #{cmd_to_run}\nError message: #{stderr}"
            end

            # The office conversion process always keeps the original name of the file and replaces
            # the extension with 'pdf', so we'll need to predict the tmp outpath and move it after.
            expected_conversion_outpath = File.join(office_temp_outdir, File.basename(src_file_path).sub(/(.+)\..+$/, '\1.pdf'))
            Derivativo::FileHelper.block_until_file_exists(expected_conversion_outpath)

            unless File.exist?(expected_conversion_outpath)
              raise Derivativo::Exceptions::ConversionError,
                    "Failed to convert document to PDF using command: #{cmd_to_run}"
            end

            # Move the generated file to the correct out_path
            FileUtils.mv(expected_conversion_outpath, dst_file_path)
            Derivativo::FileHelper.block_until_file_exists(dst_file_path)
          end
        end
      end

      def self.conversion_timeout_for_src_file(src_file_path)
        if File.size(src_file_path) < SIZE_THRESHOLD_FOR_LARGE_OFFICE_CONVERSION_DOC_TIMEOUT
          SMALL_OFFICE_CONVERSION_DOC_TIMEOUT
        else
          LARGE_OFFICE_CONVERSION_DOC_TIMEOUT
        end
      end

      def self.conversion_command(
        soffice_binary_path, src_file_path, office_temp_homedir_path, office_temp_outdir_path, first_page_only: false
      )
        [
          soffice_binary_path,
          "-env:UserInstallation=file://#{office_temp_homedir_path}",
          '--invisible',
          '--headless',
          '--convert-to',
          if first_page_only
            'pdf:writer_pdf_Export:\{\"PageRange\":\{\"type\":\"string\",\"value\":\"1\"\}\}'
          else
            'pdf:writer_pdf_Export'
          end,
          '--outdir',
          Shellwords.escape(office_temp_outdir_path),
          Shellwords.escape(src_file_path)
        ].join(' ')
      end

      def self.create_office_settings_file(soffice_homedir_path, compression_integer = 80)
        settings_file_content = <<~SETTINGS_FILE
          <?xml version="1.0" encoding="UTF-8"?>
            <oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <item oor:path="/org.openoffice.Office.Common/Filter/PDF/Export"><prop oor:name="MaxImageResolution" oor:op="fuse"><value>300</value></prop></item>
            <item oor:path="/org.openoffice.Office.Common/Filter/PDF/Export"><prop oor:name="Quality" oor:op="fuse"><value>#{compression_integer}</value></prop></item>
          </oor:items>
        SETTINGS_FILE

        settings_file_path = File.join(soffice_homedir_path, 'registrymodifications.xcu')
        IO.write(settings_file_path, settings_file_content)
        Derivativo::FileHelper.block_until_file_exists(settings_file_path)
      end
    end
  end
end
