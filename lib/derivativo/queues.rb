# frozen_string_literal: true

module Derivativo::Queues
  PREPARE_ACCESS_BASE_RASTER = :prepare_access_base_raster
  GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_ANY = :generate_access_base_raster_for_type_any
  GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_IMAGE = :generate_access_base_raster_for_type_image
  GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_DOCUMENT = :generate_access_base_raster_for_type_document
  GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_AUDIO = :generate_access_base_raster_for_type_audio
  GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_VIDEO = :generate_access_base_raster_for_type_video

  ALL_QUEUES_IN_DESCENDING_PRIORITY_ORDER = [
    PREPARE_ACCESS_BASE_RASTER,
    GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_ANY,
    GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_IMAGE,
    GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_DOCUMENT,
    GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_AUDIO,
    GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_VIDEO
  ]
end
