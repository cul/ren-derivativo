class Derivativo::CachePathBuilder
	
	TYPE_IIIF = :iiif
	VALID_TYPES = [TYPE_IIIF]
	
	attr_reader :cache_base_directory
	attr_reader :cache_iiif_directory

	def initialize(opts)
		raise 'cache_base_directory not specified' unless opts[:cache_base_directory]
    raise 'cache_iiif_directory not specified' unless opts[:cache_iiif_directory]
		
		@cache_base_directory = opts[:cache_base_directory]
		@cache_iiif_directory = opts[:cache_iiif_directory]
	end
	
	def self.factory(opts = nil, reinit=false)
    opts ||= DERIVATIVO # If opts not supplies, default to app constant DERIVATIVO
    if @path
      @path.send :initialize, opts if reinit
    else
      @path = self.new(opts)
    end
    @path
	end
	
	def self.iiif_path_for_id(id)
		factory.iiif_path_for_id(id)
	end
	
	def iiif_path_for_id(id)
		File.join(self.cache_iiif_directory, local_path_for_id(id))
	end
	
	def self.base_path_for_id(id)
		factory.base_path_for_id(id)
	end
	
	def base_path_for_id(id)
		File.join(self.cache_base_directory, local_path_for_id(id))
	end
	
	def self.local_path_for_id(id)
		factory.local_path_for_id(id)
	end
	
	def local_path_for_id(id)
		if id.start_with?('placeholder:')
			File.join('placeholder', id.gsub('placeholder:', ''))
		else
			digest = Digest::SHA256.hexdigest(id)
			File.join(digest[0..1], digest[2..3], digest[4..5], digest)
		end
	end
end
