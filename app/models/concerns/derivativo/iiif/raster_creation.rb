module Derivativo::Iiif::RasterCreation
  extend ActiveSupport::Concern
  
  def queue_create_raster
		Resque.enqueue_to(Derivativo::Queue::LOW, CreateRasterJob, raster_opts, Time.now.to_s)
	end
  
  # Creates a raster for this object's IIIF params
  # This method will raise an error if base derivative
  # generation hasn't been run yet, or is in progress.
  def create_raster
		raise "Could not create requested raster because base derivatives haven't been created yet." unless base_derivatives_complete?
		
		is_featured_region = self.region == 'featured'
    
    opts = raster_opts
    # Imogen expects format to be a symbol
		# Imogen also expects to receive :jpeg instead of :jpg
		if opts[:format] == 'jpg'
			opts = opts.merge(format: :jpeg)
		else
			opts = opts.merge(format: opts[:format].to_sym)
		end
    
    Imogen.with_image(is_featured_region ? featured_base_cache_path : base_cache_path) do |src_image|
			Imogen::Iiif.convert(src_image, raster_cache_path(true) , opts[:format] ,opts)
		end
  end
  
end