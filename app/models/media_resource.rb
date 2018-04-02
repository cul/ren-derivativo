class MediaResource < CacheableResource
  def initialize(id_or_fedora_obj)

    super(id_or_fedora_obj)

    raise "Error: Non-#{media_type} resource" unless Derivativo::FedoraObjectTypeCheck.send(:"is_generic_resource_#{media_type}?", fedora_object)
  end

  def queue_access_copy_generation(queue_name = Derivativo::Queue::MEDIA_CONVERSION_LOW)
    raise 'override this in a subclass'
  end

  def media_type
    self.class.name.downcase
  end

  def ffmpeg_args(ffmpeg_movie_object)
    DERIVATIVO[media_type + '_access_copy_settings']['ffmpeg_args'].split(' ')
  end

  def create_access_copy_if_not_exist
    # Return if Fedora object already knows about an access copy and
    # that access copy exists on the filesystem
    access_ds = fedora_object.datastreams[ACCESS_DATASTREAM_NAME]
    return if access_ds.present? && File.exists?(get_file_path_from_ds_location_value(access_ds.dsLocation))

    # Get onsite restriction status
    restricted = fedora_object.relationships(:restriction).include?(ONSITE_RESTRICTION_LITERAL_VALUE)

    access_copy_filename = DERIVATIVO[media_type + '_access_copy_settings']['filename']
    derivative_directory = Derivativo::CachePathBuilder.media_path_for_id(media_type, restricted, id)

    FileUtils.mkdir_p derivative_directory
    access_copy_path = File.join(derivative_directory, access_copy_filename)
    access_copy_processing_file_path = File.join(derivative_directory, access_copy_filename + '.processing')

    # If progress file exists, return
    return if File.exists?(access_copy_processing_file_path)

    # Touch file to block concurrent processes from trying to create an access copy
    FileUtils.touch access_copy_processing_file_path

    begin
      fedora_object.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |file_path|
        movie = FFMPEG::Movie.new(file_path)
        movie.transcode(access_copy_path, ffmpeg_args(movie))
      end
    ensure
      # Remove touched processing file after processing is complete
      FileUtils.rm access_copy_processing_file_path
    end

    # Get and store file size of access copy
    access_copy_file_size = File.size(access_copy_path)

    # Delete old datastream because we're setting all new properties
    if access_ds.present?
      access_ds.delete
    end

    # Create access datastream
    access_ds = fedora_object.create_datastream(
      ActiveFedora::Datastream,
      MediaResource::ACCESS_DATASTREAM_NAME,
      :controlGroup => 'E',
      :mimeType => DERIVATIVO[media_type + '_access_copy_settings']['mime_type'],
      :dsLabel => access_copy_filename,
      :versionable => false
    )
    access_ds.dsLocation = convert_file_path_to_ds_location_value(access_copy_path)
    fedora_object.rels_int.add_relationship(access_ds, :extent, access_copy_file_size.to_s, true) # last param *true* means that this is a literal value rather than a relationship
    fedora_object.rels_int.add_relationship(access_ds, :rdf_type, "http://pcdm.org/use#ServiceFile") # last param *true* means that this is a literal value rather than a relationship
    fedora_object.add_datastream(access_ds)
    fedora_object.save(update_index: false)

    access_copy_path
  end

  def convert_file_path_to_ds_location_value(file_path)
    # Line below will create paths like "file:/this%23_and_%26_also_something%20great/here.txt"
    # We DO NOT want a double slash at the beginnings of these paths.
    # We need to manually escape ampersands (%26) and pound signs (%23) because these are not always handled by Addressable::URI.encode()
    Addressable::URI.encode('file:' + file_path).gsub('&', '%26').gsub('#', '%23')
  end

  def get_file_path_from_ds_location_value(ds_location_value)
    Addressable::URI.unencode(ds_location_value).gsub(/^file:/, '')
  end

end
