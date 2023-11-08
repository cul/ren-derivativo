# frozen_string_literal: true

class Derivativo::DerivativePackage
  # Input fields
  attr_reader :requested_derivatives, :main_uri, :access_uri, :poster_uri
  # Generated values
  attr_reader :generated_access_tempfile, :generated_poster_tempfile, :generated_featured_region

  private attr_writer :generated_access_tempfile, :generated_poster_tempfile, :generated_featured_region

  def initialize(requested_derivatives:, main_uri:, access_uri: nil, poster_uri: nil)
    @requested_derivatives = requested_derivatives
    @main_uri = main_uri
    @access_uri = access_uri
    @poster_uri = poster_uri
  end

  def generate
    generate_access if requested_derivatives.include?(DerivativeRequest::DERIVATIVE_TYPE_ACCESS)
    generate_poster if requested_derivatives.include?(DerivativeRequest::DERIVATIVE_TYPE_POSTER)
    generate_featured_region if requested_derivatives.include?(DerivativeRequest::DERIVATIVE_TYPE_FEATURED_REGION)
  end

  def generate_access
    with_source_uri_as_file_path(self.main_uri) do |file_path|
      self.generated_access_tempfile = Derivativo::AccessGenerator.generate_as_tempfile(
        source_file_path: file_path, rotation: 0 # TODO: Handle non-0 rotations
      )
    end
    self.generated_access_tempfile
  end

  def generate_poster
    # Poster is always generated from access copy, so we'll generate an access copy if it was not
    # previously generated or supplied.
    source_uri = self.generated_access_tempfile ? file_path_as_uri(self.generated_access_tempfile.path) : self.access_uri
    source_uri ||= generate_access
    # It's possible that an access copy cannot be generated for this file, so we'll only try to
    # generate a poster if access copy generation was previously successful.
    return unless source_uri

    with_source_uri_as_file_path(source_uri) do |file_path|
      self.generated_poster_tempfile = Derivativo::PosterGenerator.generate_as_tempfile(
        source_file_path: file_path,
        poster_size: DERIVATIVO['poster_settings']['size'],
        poster_extension: DERIVATIVO['poster_settings']['extension']
      )
    end
  end

  def generate_featured_region
    # Featured region is always generated from a poster if present, and access copy is used as a
    # fallback, so we'll check for a generated or supplied poster, and will fall back to access
    # copy generation if a poster is not available.

    source_uri = self.generated_poster_tempfile ? file_path_as_uri(self.generated_poster_tempfile.path) : self.poster_uri
    source_uri ||= self.generated_access_tempfile ? file_path_as_uri(self.generated_access_tempfile.path) : self.access_uri
    source_uri ||= generate_access
    with_source_uri_as_file_path(source_uri) do |file_path|
      self.generated_featured_region = Derivativo::ImageAnalysis.auto_detect_featured_region(src_file_path: file_path)
    end
  end

  # Generates any files created by the generation of this package
  def delete
    clean_up_access_tempfile
    clean_up_poster_tempfile
  end

  def clean_up_access_tempfile
    return unless self.generated_access_tempfile && File.exist?(self.generated_access_tempfile.path)

    Rails.logger.debug("Cleaning up temporarily generated access file at: #{self.generated_access_tempfile.path}")
    self.generated_access_tempfile.close! # closes and deletes the tempfile
  end

  def clean_up_poster_tempfile
    return unless self.generated_poster_tempfile && File.exist?(self.generated_poster_tempfile.path)

    Rails.logger.debug("Cleaning up temporarily generated poster file at: #{self.generated_poster_tempfile.path}")
    self.generated_poster_tempfile.close! # closes and deletes the tempfile
  end

  def with_source_uri_as_file_path(uri)
    # Right now this method only handles 'file://' URIs, but one day we could potentially
    # point to resources hosted in a remote location (like Amazon S3), temporarily download them,
    # yield the temporary file path, and then delete the temporary file after.
    raise "Unhandled uri: #{uri}" unless uri.start_with?('file://')

    yield Addressable::URI.unencode(uri).gsub(/^file:\/\//, '')
  end

  def file_path_as_uri(file_path)
    "file://#{Addressable::URI.encode(file_path)}"
  end
end
