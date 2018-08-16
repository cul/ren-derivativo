module Derivativo::FedoraObjectTypeCheck
	def self.is_collection?(fedora_obj)
		fedora_obj.is_a?(Collection)
	end

	def self.is_generic_resource?(fedora_obj)
		fedora_obj.is_a?(GenericResource)
	end

	def self.is_rasterable_generic_resource?(fedora_obj)
		is_generic_resource_image?(fedora_obj) || is_generic_resource_pdf?(fedora_obj)
	end

	def self.is_text_extractable_generic_resource?(fedora_object)
		is_generic_resource_pdf?(fedora_object) || is_generic_resource_office_document?(fedora_object)
	end

	def self.is_generic_resource_image?(fedora_obj)
		is_generic_resource?(fedora_obj) &&
			content_mimetype_matches?(fedora_obj, /^image/)
	end

	def self.is_generic_resource_pdf?(fedora_obj)
		is_generic_resource?(fedora_obj) &&
			content_mimetype_matches?(fedora_obj, /^application\/pdf$/)
	end

	def self.is_generic_resource_office_document?(fedora_obj)
		return false unless is_generic_resource?(fedora_obj)
		# Verify mimetype
		mime_type_downcase = fedora_obj.datastreams['content'].mimeType.downcase
		return true if mime_type_downcase.match(/text|msword|ms-word|officedocument|powerpoint|excel|iwork/)
		false
	end

	def self.is_generic_resource_audio?(fedora_obj)
		is_generic_resource?(fedora_obj) && BestType.dc_type.for_mime_type(content_mime_type(fedora_obj)) == 'Sound'
	end

	def self.is_generic_resource_video?(fedora_obj)
		is_generic_resource?(fedora_obj) && BestType.dc_type.for_mime_type(content_mime_type(fedora_obj)) == 'MovingImage'
	end

	def self.is_generic_resource_audio_or_video?(fedora_obj)
		is_generic_resource_audio?(fedora_obj) || is_generic_resource_video?(fedora_obj)
	end

	def self.content_mime_type(fedora_obj)
		return '' unless (ds = fedora_obj.datastreams['content']) && (mime_type = ds.mimeType.downcase)
		mime_type
	end

	def self.content_mimetype_matches?(fedora_obj, *patterns)
		return false unless (ds = fedora_obj.datastreams['content']) && (mime_type = ds.mimeType.downcase)
		patterns.detect {|pattern| mime_type =~ pattern}
	end
end
