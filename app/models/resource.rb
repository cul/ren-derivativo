class Resource
  attr_reader :identifier, :cacheable_props

  def initialize(resource_identifier)
    @identifier = resource_identifier
    @cacheable_props = CacheableProps.new(resource_identifier)
  end

  def is_public?
    true # TODO: Get this information from the Fedora object (and cache it for faster future access)
  end

  def fedora_object
    return @fedora_object if @fedora_object
    # If the identifier resembles a pid, try a faster lookup by pid first
    @fedora_object ||= Fedora.find(self.identifier) if self.identifier =~ /^[^:]+:[^:]+$/

    # Fall back to identifier-based lookup
    @fedora_object ||= Fedora.get_pid_for_identifier(Fedora.self.identifier)
  end

  # Returns true if successful (or if access copy already exists).
  # Returns false if unable to find a usable datastream for access copy generation.
  def generate_access_copy_if_not_exist
    access_copy_exists = self.fedora_object.datastreams.keys.include?(Fedora::ACCESS_DATASTREAM_NAME)
    return true if access_copy_exists

    # Select source datastream for conversion, preferring to use service ds if present, but falling back to content ds
    datastream_to_use_for_generating_access_copy = ([Fedora::SERVICE_DATASTREAM_NAME, Fedora::CONTENT_DATASTREAM_NAME] & self.fedora_object.datastreams.keys).first
    return false if datastream_to_use_for_generating_access_copy.nil?

    Tempfile.create(['derivativo-temp-access-copy', '.png'], DERIVATIVO['tmpdir']) do |access_copy_tempfile|
      # Generate access copy
      Fedora.with_ds_resource(self.fedora_object, datastream_to_use_for_generating_access_copy, false) do |source_file_path|
        # TODO: Make this conversion work for non-image types too. As you can see below, it currently
        # assumes that we're always working with an image.

        Imogen.with_image(source_file_path, {nocache: true}) do |src_image|
          rotation = 0 # Rotation for an access copy is always 0, to match the original.  We consider rotation when generating a Derivativo base copy though.
          Imogen::Iiif.convert(src_image, access_copy_tempfile.path, 'png', {region: 'full', size: 'full', quality: 'color', rotation: rotation})
        end
      end

      # Upload the tempfile to Hyacinth as an access copy
      conn = ::Faraday.new(url: HYACINTH['url']) do |f|
        f.response :json # decode response bodies as JSON
        f.adapter :net_http # Use the Net::HTTP adapter
        f.request :authorization, :basic, HYACINTH['username'], HYACINTH['password']
        f.request :multipart
      end
      payload = {
        file: Faraday::Multipart::FilePart.new(access_copy_tempfile.path, BestType.mime_type.for_file_name(access_copy_tempfile.path))
      }
      response = conn.put("/digital_objects/#{self.fedora_object.pid}/upload_access_copy", payload)
    end
  end

  def base_available?
    available = File.exist?(Derivativo::CachePath.base_path_for(identifier))
    if !available && identifier.start_with?('placeholder:')
      Rails.logger.error("Could not find source placeholder for '#{identifier}'.  Restart the application to regenerate the placeholder base images.")
      raise Derivativo::Exceptions::PlaceholderBaseNotFoundError, "Placeholder base image not found.  See log for details."
    end
    available
  end

  def base_cache_path(make_dirs = false)
    path = Derivativo::CachePath.base_path_for(self.identifier)
    FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
  end

  def iiif_dir_path(make_dirs = false)
    path = Derivativo::CachePath.iiif_dir_path_for(self.identifier)
    FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
  end

  def destroy_base_and_iiif_cache!
    FileUtils.rm_rf(base_cache_path)
    FileUtils.rm_rf(iiif_dir_path)
  end

  def raster_path(raster_opts, make_dirs = false)
    path = File.join(iiif_dir_path, raster_opts[:region], raster_opts[:size], raster_opts[:rotation], "#{raster_opts[:quality]}.#{raster_opts[:format]}")
    FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
  end

  # Generates a raster for the given raster_opts.
  # If generate_base_if_not_exist is true, it will first generate the base image if a base is not found.
  # If generate_base_if_not_exist is false AND no base exists, it will raise an exception.
  def generate_raster(raster_opts, generate_base_if_not_exist)
    path_to_base_image = self.base_cache_path

    if !File.exist?(path_to_base_image)
      raise Derivativo::BaseNotFoundError if !generate_base_if_not_exist
      self.generate_base
    end

    Imogen.with_image(path_to_base_image, {nocache: true}) do |src_image|
			Imogen::Iiif.convert(src_image, raster_path(raster_opts, true), raster_opts[:format], raster_opts)
		end

    #Derivativo::Utils::FileUtils.block_until_file_exists(raster_cache_path) # TODO: account for network disk delays
  end

  def generate_base(generate_access_if_not_exist)
    self.generate_access_copy_if_not_exist if generate_access_if_not_exist

    # Use the Fedora access copy to generate the base. If no Fedora access copy exists, we'll throw an error.
    raise Derivativo::Exceptions::AccessCopyNotFoundError unless self.fedora_object.datastreams.keys.include?(Fedora::ACCESS_DATASTREAM_NAME)

    # If we got here, we have an access copy to use for generating the base copy.
    rotation = Fedora.get_orientation_property_if_exist(self.fedora_object, 0)
    Fedora.with_ds_resource(self.fedora_object, Fedora::ACCESS_DATASTREAM_NAME, false) do |access_copy_file_path|
      Imogen.with_image(access_copy_file_path, {nocache: true}) do |src_image|
        # The first time we generate the base image, we'll also store the original width and height in Fedora
        Fedora.set_width_and_height(self.fedora_object, src_image.width, src_image.height)
        Imogen::Iiif.convert(src_image, base_cache_path(true), 'png', {region: 'full', size: 'full', quality: 'color', rotation: rotation})
      end
    end

    #Derivativo::Utils::FileUtils.block_until_file_exists(raster_cache_path) # TODO: account for network disk delays
  end

  def base_dimensions
    return @base_dimensions if @base_dimensions

    # TODO: Try to get from cache

    # Fall back to reading image dimensions from base on filesystem
    base_path = self.base_cache_path
    return [nil, nil] unless File.exist?(base_path)
    Imogen.with_image(base_path, {nocache: true}) { |img| @base_dimensions = [img.width, img.height] }

    @base_dimensions
  end
end
