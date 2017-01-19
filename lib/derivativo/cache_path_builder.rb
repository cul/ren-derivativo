class Derivativo::CachePathBuilder
	
	TYPE_IIIF = :iiif
	VALID_TYPES = [TYPE_IIIF]
	
	attr_reader :base_directory

	def initialize(opts)
		@base_directory = opts[:cache_directory]
	end
	
	def self.factory(opts = nil, reinit=false)
    opts ||= DERIVATIVO # If opts not supplies, default to app constant DERIVATIVO
    raise 'Cache directory not specified' unless opts[:cache_directory]
    if @path
      @path.send :initialize, opts if reinit
    else
      @path = self.new(opts)
    end
    @path
	end
	
	def self.path_for_id(id)
		factory.path_for_id(id)
	end
	
	def path_for_id(id)
		if id.start_with?('placeholder:')
			File.join(self.base_directory, 'placeholder', id.gsub('placeholder:', ''))
		else
			digest = Digest::SHA256.hexdigest(id)
			File.join(self.base_directory, digest[0..1], digest[2..3], digest[4..5], digest)
		end
	end
	
	def self.path_for_type(id, type)
		factory.path_for_type(id, type)
	end
	
	def path_for_type(id, type)
		raise 'Invalid type' unless VALID_TYPES.include?(type)
		dir_for_id = path_for_id(id)
		case type
		when TYPE_IIIF
			File.join(dir_for_id, 'iiif')
		end
	end
end
