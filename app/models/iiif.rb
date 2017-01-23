class Iiif
  include Derivativo::Iiif::DbCache
  include Derivativo::Iiif::FedoraPropertyRetrieval
  include Derivativo::Iiif::CachableProperties
  include Derivativo::Iiif::CachePath
  include Derivativo::Iiif::Info
  include Derivativo::Iiif::BaseCreation
  include Derivativo::Iiif::CreateAndStore
  include Derivativo::Iiif::RasterCreation
  
  TILE_SIZE = 512
  FORMATS = {'jpg' => 'image/jpeg', 'png' => 'image/png'}
  
  attr_reader :id, :version, :region, :size, :rotation, :quality, :format
  
  def initialize(opts)
    @id = opts[:id]
    @version = opts.fetch(:version, '2')
    @region = opts.fetch(:region, 'full')
    @size = opts.fetch(:size, 'full')
    @rotation = opts.fetch(:rotation, '0').to_s # .to_s in case someone passes an integer value because we expect a string
    @quality = opts.fetch(:quality, 'native')
    @format = opts.fetch(:format, 'jpg')
  end
  
  def raster_opts
		HashWithIndifferentAccess.new({
			id: id,
			region: region,
			size: size,
			rotation: rotation,
			quality: quality,
			format: format
		})
	end
  
end
