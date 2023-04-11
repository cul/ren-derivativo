module Derivativo::CachePath
  BASE_FILE_NAME = 'base.png'

  def self.base_path_for(identifier)
    File.join(DERIVATIVO[:cache_base_directory], self.relative_path_for(identifier), BASE_FILE_NAME)
  end

  def self.iiif_dir_path_for(identifier)
    File.join(DERIVATIVO[:cache_iiif_directory], self.relative_path_for(identifier))
  end

  def self.relative_path_for(identifier)
    if identifier.start_with?('placeholder:')
			File.join('placeholder', identifier.gsub('placeholder:', ''))
		else
			digest = Digest::SHA256.hexdigest(identifier)
			File.join(digest[0..1], digest[2..3], digest[4..5], digest)
		end
  end
end
