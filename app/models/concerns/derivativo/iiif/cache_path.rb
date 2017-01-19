module Derivativo::Iiif::CachePath
  extend ActiveSupport::Concern
  
  BASE_FILE_NAME = 'base.png'
  FEATURED_BASE_FILE_NAME = 'featured_base.png'
  
  def base_cache_path(make_dirs = false)
    path = File.join(Derivativo::CachePathBuilder.path_for_id(self.id), BASE_FILE_NAME)
    FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
  end

	def featured_base_cache_path(make_dirs = false)
		path = File.join(Derivativo::CachePathBuilder.path_for_id(self.id), FEATURED_BASE_FILE_NAME)
		FileUtils.mkdir_p(File.dirname(path)) if make_dirs
    path
	end
  
  def raster_cache_path(make_dirs = false)
    @raster_cache_path ||= File.join(
      Derivativo::CachePathBuilder.path_for_type(self.id, Derivativo::CachePathBuilder::TYPE_IIIF),
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
  
  def featured_base_exists?
    File.exists?(featured_base_cache_path)
  end
  
end