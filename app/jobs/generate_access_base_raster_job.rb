class GenerateAccessBaseRasterJob < ApplicationJob
  queue_as Derivativo::Queues::GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_ANY

  # Generates the access copy, base copy, and specific raster for the given resource.
  # Does not regenerate the access, base, or raster if they already exist.
  # If raster_opts is given a value of nil, specific raster generation will be skipped
  # and only access and base generation will occur.
  def perform(identifier:, raster_opts:)
    resource = Resource.new(identifier)

    resource.cacheable_props.db_cache_record.with_lock do
      return if resource.cacheable_props.processing
      resource.cacheable_props.processing = true
      puts 'set processing to true'
    end

    resource.generate_access_copy_if_not_exist
    resource.generate_base(false)
    resource.generate_raster(raster_opts, false) unless raster_opts.nil?
  ensure
    resource.cacheable_props.processing = false
    puts 'set processing to false'
  end
end
