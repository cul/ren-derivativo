module Derivativo::FedoraObjectTypeCheck

	def self.is_generic_resource?(fedora_obj)
		return false if fedora_obj.nil?
		return false unless fedora_obj.is_a?(GenericResource)
		true
	end
	
	def self.is_rasterable_generic_resource?(fedora_obj)
		return is_generic_resource_image?(fedora_obj) || is_generic_resource_pdf?(fedora_obj)
	end
	
	def self.is_generic_resource_image?(fedora_obj)
		return false unless is_generic_resource?(fedora_obj)
		# Verify mimetype
		mime_type_downcase = fedora_obj.datastreams['content'].mimeType.downcase
		return false unless mime_type_downcase.start_with?('image')
		true
	end
	
	def self.is_generic_resource_pdf?(fedora_obj)
		return false unless is_generic_resource?(fedora_obj)
		# Verify mimetype
		mime_type_downcase = fedora_obj.datastreams['content'].mimeType.downcase
		return false unless mime_type_downcase == 'application/pdf'
		true
	end
end