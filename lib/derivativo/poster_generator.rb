# frozen_string_literal: true

module Derivativo::PosterGenerator
  # Generates a poster and returns a Tempfile that references the poster.
  # Returns nil if the source file cannot be converted into a poster.
  def self.generate_as_tempfile(source_file_path:, poster_size:, poster_extension:)
    # TODO: Handle poster generation for non-image-based sources
    output_tempfile = Derivativo::FileHelper.working_directory_temp_file('poster', ".#{poster_extension}")
    output_path = self.generate(
      source_file_path: source_file_path, poster_size: poster_size, output_file_path: output_tempfile.path
    )
    output_path ? output_tempfile : nil
  rescue Derivativo::Exceptions::UnhandledFileType
    nil
  end

  def self.generate(source_file_path:, poster_size:, output_file_path:)
    # TODO: Handle additional source file types
    source_pdcm_type = BestType.pcdm_type.for_file_name(source_file_path)
    if source_pdcm_type == BestType::PcdmTypeLookup::VIDEO
      Derivativo::Conversion.video_to_image(
        src_file_path: source_file_path, dst_file_path: output_file_path, size: poster_size
      )
    elsif source_file_path.ends_with?('.pdf')
      Derivativo::Conversion.pdf_to_image(
        src_file_path: source_file_path, dst_file_path: output_file_path, size: poster_size
      )
    else
      unhandled_type_message = 'Unable to generate poster for source file: '\
        "#{source_file_path} (pdcm type #{source_pdcm_type})"
      Rails.logger.info(unhandled_type_message)
      raise Derivativo::Exceptions::UnhandledFileType, unhandled_type_message
    end
    output_file_path
  end
end
