# frozen_string_literal: true

module Derivativo::AccessGenerator
  # Generates an access copy and returns a Tempfile that references the access copy.
  # Returns nil if the source file cannot be converted into an access copy.
  def self.generate_as_tempfile(source_file_path:, rotation:)
    # TODO: Handle additional source file types
    output_tempfile_extension = self.access_output_file_extension_for_source_file(source_file_path)
    output_tempfile = Derivativo::FileHelper.working_directory_temp_file('access', ".#{output_tempfile_extension}")
    self.generate(source_file_path: source_file_path, rotation: rotation, output_file_path: output_tempfile.path)
    output_tempfile
  rescue Derivativo::Exceptions::UnhandledFileType
    nil
  end

  # For the given source file, returns the file extension that should be used when an access copy
  # of this file is generated.
  def self.access_output_file_extension_for_source_file(source_file_path)
    source_pdcm_type = BestType.pcdm_type.for_file_name(source_file_path)
    if source_pdcm_type == BestType::PcdmTypeLookup::IMAGE
      DERIVATIVO['image_access_copy_settings']['extension']
    elsif source_pdcm_type == BestType::PcdmTypeLookup::VIDEO
      DERIVATIVO['video_access_copy_settings']['extension']
    elsif source_pdcm_type == BestType::PcdmTypeLookup::AUDIO
      DERIVATIVO['audio_access_copy_settings']['extension']
    elsif text_or_office_document_type?(source_pdcm_type)
      'pdf'
    else
      unhandled_type_message = 'Unable to determine output file extension for source file: '\
        "#{source_file_path} (pdcm type #{source_pdcm_type})"
      Rails.logger.info(unhandled_type_message)
      raise Derivativo::Exceptions::UnhandledFileType, unhandled_type_message
    end
  end

  def self.generate(source_file_path:, rotation:, output_file_path:)
    # TODO: Handle additional source file types
    source_pdcm_type = BestType.pcdm_type.for_file_name(source_file_path)
    if source_pdcm_type == BestType::PcdmTypeLookup::IMAGE
      Derivativo::Conversion.image_to_image(
        src_file_path: source_file_path, dst_file_path: output_file_path, rotation: rotation
      )
    elsif source_pdcm_type == BestType::PcdmTypeLookup::VIDEO
      Derivativo::Conversion.video_to_video(
        src_file_path: source_file_path, dst_file_path: output_file_path,
        ffmpeg_input_args: DERIVATIVO['video_access_copy_settings']['ffmpeg_input_args'],
        ffmpeg_output_args: DERIVATIVO['video_access_copy_settings']['ffmpeg_output_args']
      )
    elsif source_pdcm_type == BestType::PcdmTypeLookup::AUDIO
      Derivativo::Conversion.audio_to_audio(
        src_file_path: source_file_path, dst_file_path: output_file_path,
        ffmpeg_input_args: DERIVATIVO['audio_access_copy_settings']['ffmpeg_input_args'],
        ffmpeg_output_args: DERIVATIVO['audio_access_copy_settings']['ffmpeg_output_args']
      )
    elsif source_file_path.ends_with?('.pdf')
      Derivativo::Conversion.pdf_to_pdf(
        src_file_path: source_file_path, dst_file_path: output_file_path
      )
    elsif text_or_office_document_type?(source_pdcm_type)
      Derivativo::Conversion.text_or_office_document_to_pdf(
        src_file_path: source_file_path, dst_file_path: output_file_path
      )
    else
      unhandled_type_message = 'Unable to generate access copy for source file: '\
        "#{source_file_path} (pdcm type #{source_pdcm_type})"
      Rails.logger.info(unhandled_type_message)
      raise Derivativo::Exceptions::UnhandledFileType, unhandled_type_message
    end
    output_file_path
  end

  def self.text_or_office_document_type?(pdcm_type)
    [
      BestType::PcdmTypeLookup::PAGE_DESCRIPTION,
      BestType::PcdmTypeLookup::PRESENTATION,
      BestType::PcdmTypeLookup::SPREADSHEET,
      BestType::PcdmTypeLookup::TEXT
    ].include?(pdcm_type)
  end
end
