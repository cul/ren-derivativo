module Derivativo::Iiif::CachePath
  extend ActiveSupport::Concern
  
  BASE_FILE_NAME = 'base.png'
  ZOOMING_TILES_COMPLETE_FILENAME = 'zooming_tiles_complete'
  
  def base_cache_path(make_dirs = false)
    path = File.join(Derivativo::CachePathBuilder.base_path_for_id(self.id), BASE_FILE_NAME)
    FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
  end
	
	def iiif_cache_dir_path(make_dirs = false)
		path = Derivativo::CachePathBuilder.iiif_path_for_id(self.id)
		FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
	end
  
  def raster_cache_path(make_dirs = false)
    @raster_cache_path ||= File.join(
      iiif_cache_dir_path,
      self.region,
      self.size,
      self.rotation,
      "#{self.quality}.#{self.format}"
    )
    FileUtils.mkdir_p(File.dirname(@raster_cache_path)) if make_dirs
    @raster_cache_path
  end
  
  def raster_exists?
    File.exists?(raster_cache_path)
  end
  
  def base_exists?
    File.exists?(base_cache_path)
  end
  
  # Checks to see if IIIF tiles exist for a zooming image viewer.
  # Returns true only if ALL expected tiles exist
  def zooming_image_tiles_exist?
		File.exists?(zooming_tiles_complete_file_path)
	end
  
  def touch_zooming_image_tiles_complete_file
		FileUtils.touch zooming_tiles_complete_file_path
	end
  
  def zooming_tiles_complete_file_path
		File.join(iiif_cache_dir_path, ZOOMING_TILES_COMPLETE_FILENAME)
  end
end