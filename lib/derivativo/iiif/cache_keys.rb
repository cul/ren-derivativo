module Derivativo::Iiif::CacheKeys
  extend ActiveSupport::Concern

  DC_TYPES_TO_PLACEHOLDER_TYPES = {
    'File' => 'file',
    'MovingImage' => 'moving_image',
    'Software' => 'software',
    'Sound' => 'sound',
    'Text' => 'text',
    'PageDescription' => 'text',
    'Closed' => 'locked'
  }

  ORIGINAL_IMAGE_DIMENSIONS_KEY = :original_image_dimensions
  SCALE_FACTORS_KEY = :scale_factors
  IS_RESTRICTED_SIZE_IMAGE_KEY = :is_restricted_size_image
  REPRESENTATIVE_RESOURCE_DC_TYPE_KEY = :representative_resource_dc_type
  PLACEHOLDER_IMAGE_TYPE_KEY = :placeholder_image_type
  REPRESENTATIVE_RESOURCE_ID_KEY = :representative_resource_id
  REPRESENTATIVE_RESOURCE_CLOSED_KEY = :representative_resource_closed
  FEATURED_REGION_KEY = :featured_region
  PROPERTY_CACHE_KEYS = [
    ORIGINAL_IMAGE_DIMENSIONS_KEY, SCALE_FACTORS_KEY, IS_RESTRICTED_SIZE_IMAGE_KEY, REPRESENTATIVE_RESOURCE_DC_TYPE_KEY,
    PLACEHOLDER_IMAGE_TYPE_KEY, REPRESENTATIVE_RESOURCE_ID_KEY, REPRESENTATIVE_RESOURCE_CLOSED_KEY, FEATURED_REGION_KEY
  ]
end
