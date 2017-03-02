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
    else
      raise "Invalid key for fedora property: #{key}"
    end
  end
  
  def fedora_get_original_image_dimensions
    representative_generic_resource = fedora_get_representative_generic_resource
    return [0, 0] if representative_generic_resource.nil?
    
    # Get image dimensions from Fedora object, or get dimensions from original content if unavailable (and save those dimensions in Fedora for future retrieval)
    content_ds = representative_generic_resource.datastreams['content']
    rels_int = representative_generic_resource.rels_int
    original_image_width = rels_int.relationships(content_ds, :image_width).first.object.value.to_i if rels_int.relationships(content_ds, :image_width).present?
    original_image_height = rels_int.relationships(content_ds, :image_length).first.object.value.to_i if rels_int.relationships(content_ds, :image_length).present?
    if original_image_width.blank? || original_image_height.blank?
      representative_generic_resource.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |image_path|
        Imogen.with_image(image_path) do |img|
          original_image_width = img.width
          original_image_height = img.height
          rels_int.clear_relationship(content_ds, :image_width)
          rels_int.clear_relationship(content_ds, :image_length)
          rels_int.add_relationship(content_ds, :image_width, original_image_width.to_s, true)
          rels_int.add_relationship(content_ds, :image_length, original_image_height.to_s, true)
        end
      end
      Retriable.retriable on: [RestClient::RequestTimeout], tries: 3, base_interval: 5 do
        rels_int.content = rels_int.to_rels_int # We're doing this because there's some weird bug in the rels_int gem (ds doesn't know it was updated)
        rels_int.save if rels_int.changed?
      end
    end
    [original_image_width.to_i || 0, original_image_height.to_i || 0]
  end
  
  def fedora_get_is_restricted_size_image
    representative_generic_resource = fedora_get_representative_generic_resource
    return false if representative_generic_resource.nil?
    return representative_generic_resource.relationships(:restriction).include?('size restriction')
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
      if fedora_object.nil?
        nil
      else
        fedora_object.get_representative_generic_resource
      end
    end
  end
  
  def fedora_get_representative_generic_resource_id
    fedora_get_representative_generic_resource.present? ? fedora_get_representative_generic_resource.pid : nil
  end
  
  def fedora_get_featured_region
    representative_generic_resource = fedora_get_representative_generic_resource
    return nil if representative_generic_resource.nil?
    
    # Get featured region from Fedora object, or auto-detect a featured region (and save that featured region in Fedora for future retrieval)
    featured_region = representative_generic_resource.relationships(:region_featured).first.to_s if representative_generic_resource.relationships(:region_featured).present?
    
    if featured_region.blank?
      representative_generic_resource.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |image_path|
        Imogen.with_image(image_path) do |img|
          # No featured region has been set, so we'll use Imogen's AutoCrop feature detection to set a "best guess" featured region
					frame = Imogen::AutoCrop::Edges.new(img)
					x1, y1, x2, y2 = frame.get([img.width, img.height].min)
					x = x1
					y = y1
					width = x2-x1
					height = y2-y1
					featured_region = [x, y, width, height].join(',')
					representative_generic_resource.add_relationship(:region_featured, featured_region, true)
        end
      end
      Retriable.retriable on: [RestClient::RequestTimeout], tries: 3, base_interval: 5 do
        representative_generic_resource.save(update_index: false)
      end
    end
    featured_region
  end
  
end