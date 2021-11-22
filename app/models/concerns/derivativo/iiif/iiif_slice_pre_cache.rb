module Derivativo::Iiif::IiifSlicePreCache
  extend ActiveSupport::Concern

  def queue_iiif_slice_pre_cache
		Resque.enqueue_to(Derivativo::Queue::LOW, IiifSlicePreCacheJob, id, Time.now.to_s)
	end

  # Pre-caches IIIF slices for the OpenSeadragon zooming image viewer
  # This method will raise an error if base derivative
  # generation hasn't been run yet, or is in progress.
  def create_iiif_slice_pre_cache
		raise 'Could not pre-cache iiif slices because base derivatives are currently being created.' unless base_derivatives_complete?

		# After base creation, also pre-cache IIIF slices for zooming images
		# If we don't do this, it will take way too long (sometimes 15 seconds)
		# for the IIIF zooming image viewer to load (while it creates these derivatives)
		unless zooming_image_tiles_exist?
			# Create IIIF zooming images slices
			iiif_dir = iiif_cache_dir_path(true)
			Imogen.with_image(base_cache_path) do |img|
				Rails.logger.debug 'Creating zooming image tiles...'
				start_time = Time.now
				Imogen::Iiif::Tiles.for(img, iiif_dir, :jpeg, IiifResource::TILE_SIZE) do |bitmap, tile_dest_path, format, iiif_opts|
					FileUtils.mkdir_p(File.dirname(tile_dest_path))
					Imogen::Iiif.convert(bitmap,tile_dest_path,format,iiif_opts)
				end
				touch_zooming_image_tiles_complete_file
				Rails.logger.debug 'Created zooming image tiles in ' + (Time.now-start_time).to_s + ' seconds'
			end
		end

  end

end
