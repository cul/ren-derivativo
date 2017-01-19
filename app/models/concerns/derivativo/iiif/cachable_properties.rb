module Derivativo::Iiif::CachableProperties
  extend ActiveSupport::Concern
  
  def self.included(base)
    # Ensure that private methods exist in this module for all PROPERTY_CACHE_KEYS
    Derivativo::Iiif::CacheKeys::PROPERTY_CACHE_KEYS.each do |cache_key|
			raise "Missing required method definition #{cache_key} in module #{self.name}" unless self.private_method_defined?(cache_key)
		end
  end
  
  def clear_cachable_properties
		# Remove rails cache entry
		
    # Clear database cache for this record
    db_cache_record.data = {}
    db_cache_record.save
      
    Derivativo::Iiif::CacheKeys::PROPERTY_CACHE_KEYS.each do |cache_key|
			# Remove instance variable for this key
			remove_instance_variable(('@' + cache_key.to_s).to_sym)
      # Clear Rails cache for this key
      Rails.cache.delete(rails_cache_identifier_for_key(cache_key))
    end
  end
  
  def warm_cachable_properties
    Derivativo::Iiif::CacheKeys::PROPERTY_CACHE_KEYS.each do |cache_key|
			get_cachable_property(cache_key)
		end
  end
  
  def rails_cache_identifier_for_key(cache_key)
		cache_key.to_s + ':' + self.id
	end
  
  def get_cachable_property(cache_key, refresh_cache=false)
    raise "Invalid cache key: #{cache_key}" unless Derivativo::Iiif::CacheKeys::PROPERTY_CACHE_KEYS.include?(cache_key)
    
    Rails.cache.delete(rails_cache_identifier_for_key(cache_key)) if refresh_cache
    
    # Cache in instance variable in case this variable is accessed multiple times for the same object
    instance_variable_symbol = ('@' + cache_key.to_s).to_sym
    return instance_variable_get(instance_variable_symbol) if instance_variable_defined?(instance_variable_symbol)
		
    # Retrieve from Rails cache (or set in Rails cache if not already set)
    value = Rails.cache.fetch(rails_cache_identifier_for_key(cache_key)) do
			# First try to get the value from the database cache
			next db_cache_get(cache_key) if db_cache_has?(cache_key)
			# If not in database cache, use fallback method to retrievae the value
			# self.included method in this module module ensures that same-name methods will be defined for all cache keys
			val = self.send(cache_key)
			# Cache value in db cache
			db_cache_set(cache_key, val)
			# And return the value
			val
    end
    
    # Set and return value cached as instance variable
    instance_variable_set(instance_variable_symbol, value)
  end
  
  def has_placeholder_image?
		get_cachable_property(Derivativo::Iiif::CacheKeys::PLACEHOLDER_IMAGE_TYPE_KEY).present?
	end
  
  def has_representative_resource_id?
		get_cachable_property(Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_ID_KEY).present?
	end
  
  private
  
  def original_image_dimensions
    fedora_get_original_image_dimensions
  end
  
  def scale_factors
		original_width, original_height = original_image_dimensions
		Imogen::Iiif::Tiles.scale_factor_for(original_width, original_height, Iiif::TILE_SIZE)
	end
  
  def is_restricted_size_image
		fedora_get_is_restricted_size_image
  end
  
  def representative_resource_dc_type
		fedora_get_representative_generic_resource_dc_type
	end
  
  def placeholder_image_type
		dc_type = fedora_get_representative_generic_resource_dc_type
		
		# If no dc_type is returned, then that means that
		# there is no representative resource, so we want to
		# display a generic file placeholder icon
		return 'file' if dc_type.nil?
    
     # If this resource is rasterable, return nil. We don't want to serve a placeholder for it.
    return nil if is_rasterable_generic_resource?(fedora_get_representative_generic_resource)
    Derivativo::Iiif::CacheKeys::DC_TYPES_TO_PLACEHOLDER_TYPES[dc_type] || 'file'
  end
  
  def representative_resource_id
		fedora_get_representative_generic_resource_id
  end
  
end