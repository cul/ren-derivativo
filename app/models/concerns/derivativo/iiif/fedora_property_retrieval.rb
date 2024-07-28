module Derivativo::Iiif::FedoraPropertyRetrieval
  extend ActiveSupport::Concern

  def fedora_object
    @fedora_object ||= begin
      begin
        ActiveFedora::Base.find(self.id)
      rescue ActiveFedora::ObjectNotFoundError
        Rails.logger.error "Could not find Fedora object with PID: " + self.id
        nil
      end
    end
  end

  def fedora_property_get(key)
    case key
    when Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY
      fedora_get_original_image_dimensions
    when Derivativo::Iiif::CacheKeys::IS_RESTRICTED_SIZE_IMAGE_KEY
      fedora_get_is_restricted_size_image
    when Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_DC_TYPE_KEY
      fedora_get_representative_generic_resource_dc_type
    when Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_ID_KEY
      fedora_get_representative_generic_resource_id
    when Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_CLOSED_KEY
      fedora_get_representative_generic_resource_closed
    else
      raise "Invalid key for fedora property: #{key}"
    end
  end

  # @return [Array<Integer>] width, height of base (full) derivative
  def fedora_get_original_image_dimensions
    representative_generic_resource = fedora_get_representative_generic_resource
    return [0, 0] if representative_generic_resource.nil?

    # Get image dimensions from Fedora object, or get dimensions from original content if unavailable (and save those dimensions in Fedora for future retrieval)
    content_ds = representative_generic_resource.datastreams['content']
    rels_int = representative_generic_resource.rels_int
    original_image_width = rels_int.relationships(content_ds, :image_width).first.object.value.to_i if rels_int.relationships(content_ds, :image_width).present?
    original_image_height = rels_int.relationships(content_ds, :image_length).first.object.value.to_i if rels_int.relationships(content_ds, :image_length).present?
    if original_image_width.blank? || original_image_height.blank?
      begin
        representative_generic_resource.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |image_path|
          if Derivativo::FedoraObjectTypeCheck.is_generic_resource_video?(representative_generic_resource)
            movie = FFMPEG::Movie.new(image_path)
            original_image_width = movie.width
            original_image_height = movie.height
          else
            Imogen.with_image(image_path) do |img|
              original_image_width = img.width
              original_image_height = img.height
            end
          end
        end
      rescue Vips::Error
        # If we fail to read the file because it's not a readable format, we'll try reading the access copy instead
        representative_generic_resource.with_ds_resource('access', (! DERIVATIVO['no_mount']) ) do |image_path|
          if Derivativo::FedoraObjectTypeCheck.is_generic_resource_video?(representative_generic_resource, 'access')
            movie = FFMPEG::Movie.new(image_path)
            original_image_width = movie.width
            original_image_height = movie.height
          else
            Imogen.with_image(image_path) do |img|
              original_image_width = img.width
              original_image_height = img.height
            end
          end
        end
      end
      rels_int.clear_relationship(content_ds, :image_width)
      rels_int.clear_relationship(content_ds, :image_length)
      rels_int.add_relationship(content_ds, :image_width, original_image_width.to_s, true)
      rels_int.add_relationship(content_ds, :image_length, original_image_height.to_s, true)
      Retriable.retriable on: [RestClient::RequestTimeout], tries: 3, base_interval: 5 do
        rels_int.content = rels_int.to_rels_int # We're doing this because there's some weird bug in the rels_int gem (ds doesn't know it was updated)
        rels_int.save if rels_int.changed?
      end
    end
    # if the image is rotated 90, 270, 450, etc then source dimensions must be rotated
    if (representative_generic_resource.required_rotation_for_upright_display / 10).odd?
      [original_image_height.to_i || 0, original_image_width.to_i || 0]
    else
      [original_image_width.to_i || 0, original_image_height.to_i || 0]
    end
  end

  def fedora_get_is_restricted_size_image
    representative_generic_resource = fedora_get_representative_generic_resource
    return false if representative_generic_resource.nil?
    return !!representative_generic_resource.access_levels.map(&:downcase).detect {|v| !"public access".eql?(v) }
  end

  def fedora_get_representative_generic_resource_dc_type
    representative_generic_resource = fedora_get_representative_generic_resource
    return nil if representative_generic_resource.nil?
    representative_generic_resource.datastreams['DC'].dc_type.first
  end

  def fedora_get_representative_generic_resource
    # If previously defined, @representative_generic_resource may have been assigned a value of nil,
    # and if so, we want to return that nil value
    return @representative_generic_resource if instance_variable_defined?(:@representative_generic_resource)

    @representative_generic_resource ||= begin
      # For certain very old Fedora objects with improper cmodel data, the Fedora class
      # is ActiveFedora::Base instead of one of our custom classes (like GenericResource).
      # ActiveFedora fails to properly cast those objects, so they don't have a
      # get_representative_generic_resource that we can call.
      if fedora_object.nil? || fedora_object.class == ActiveFedora::Base
        nil
      else
        fedora_object.get_representative_generic_resource
      end
    end
  end

  def fedora_get_representative_generic_resource_id
    fedora_get_representative_generic_resource.present? ? fedora_get_representative_generic_resource.pid : nil
  end

  def fedora_get_representative_generic_resource_closed
    fedora_get_representative_generic_resource.present? ? fedora_get_representative_generic_resource.closed? : nil
  end

  def fedora_get_featured_region
    representative_generic_resource = fedora_get_representative_generic_resource
    return nil if representative_generic_resource.nil?

    # Get featured region from Fedora object, or auto-detect a featured region (and save that featured region in Fedora for future retrieval)
    featured_region = representative_generic_resource.relationships(:region_featured).first.to_s if representative_generic_resource.relationships(:region_featured).present?

    if featured_region.blank?
			if base_derivatives_complete?
				featured_region = featured_region_for_image(base_cache_path)
			else
				representative_generic_resource.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |image_path|
					featured_region = featured_region_for_image(image_path)
				end
			end

			representative_generic_resource.add_relationship(:region_featured, featured_region, true)

      Retriable.retriable on: [RestClient::RequestTimeout], tries: 3, base_interval: 5 do
        representative_generic_resource.save(update_index: false)
      end
    end
    featured_region
  end

  def featured_region_for_image(image_path)
    x = y = width = height = nil
    Imogen.with_image(image_path) do |img|
      # We try to use at least 768 pixels from any image when generating a featured
      # area crop so that we don't unintentionally get a tiny 10px x 10px crop
      # that ends up getting scaled up for users and looks blocky/blurry.
      left_x, top_y, right_x, bottom_y = Imogen::Iiif::Region::Featured.get(img, 768)
      x = left_x
      y = top_y
      width = right_x - left_x
      height = bottom_y - top_y
    end
    [x, y, width, height].join(',')
	end
end
