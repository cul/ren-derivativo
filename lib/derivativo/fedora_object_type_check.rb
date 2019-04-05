module Derivativo::FedoraObjectTypeCheck
	def self.is_collection?(fedora_obj)
		fedora_obj.is_a?(Collection)
	end

	def self.is_generic_resource?(fedora_obj)
		fedora_obj.is_a?(GenericResource)
	end

	def self.is_rasterable_generic_resource?(fedora_obj, dsid='content')
		is_generic_resource_image?(fedora_obj, dsid) ||
		is_generic_resource_pdf?(fedora_obj, dsid) ||
		is_generic_resource_rasterable_video?(fedora_obj, dsid)
	end

	def self.is_text_extractable_generic_resource?(fedora_object, dsid='content')
		is_generic_resource_pdf?(fedora_object,dsid) || is_generic_resource_office_document?(fedora_object, dsid)
	end

	def self.is_generic_resource_image?(fedora_obj, dsid='content')
		is_generic_resource?(fedora_obj) &&
			datastream_mimetype_matches?(fedora_obj, dsid, /^image/)
	end

	def self.is_generic_resource_pdf?(fedora_obj, dsid='content')
		is_generic_resource?(fedora_obj) &&
			datastream_mimetype_matches?(fedora_obj, dsid, /^application\/pdf$/)
	end

	def self.is_generic_resource_office_document?(fedora_obj, dsid='content')
		return false unless is_generic_resource?(fedora_obj)
		# Verify mimetype
		mime_type_downcase = fedora_obj.datastreams[dsid].mimeType.downcase
		return true if mime_type_downcase.match(/text|msword|ms-word|officedocument|powerpoint|excel|iwork/)
		false
	end

	def self.is_generic_resource_audio?(fedora_obj, dsid='content')
		is_generic_resource?(fedora_obj) && BestType.dc_type.for_mime_type(datastream_mime_type(fedora_obj, dsid)) == 'Sound'
	end

	def self.is_generic_resource_video?(fedora_obj, dsid='content')
		is_generic_resource?(fedora_obj) && BestType.dc_type.for_mime_type(datastream_mime_type(fedora_obj, dsid)) == 'MovingImage'
	end

	def is_generic_resource_rasterable_video?(fedora_obj, dsid='content')
		is_generic_resource_video?(fedora_obj) &&
			datastream_mimetype_matches?(fedora_obj, dsid, /^video\/mp4$/)
	end

	def self.is_generic_resource_audio_or_video?(fedora_obj, dsid='content')
		is_generic_resource_audio?(fedora_obj, dsid) || is_generic_resource_video?(fedora_obj, dsid)
	end

	def self.datastream_mime_type(fedora_obj, dsid)
		return '' unless (ds = fedora_obj.datastreams[dsid]) && (mime_type = ds.mimeType.downcase)
		mime_type
	end

	def self.datastream_mimetype_matches?(fedora_obj, dsid, *patterns)
		return false unless (ds = fedora_obj.datastreams[dsid]) && (mime_type = ds.mimeType.downcase)
		patterns.detect {|pattern| mime_type =~ pattern}
	end

	def self.content_mime_type(fedora_obj)
		datastream_mime_type(fedora_obj, 'content')
	end

	def self.content_mimetype_matches?(fedora_obj, *patterns)
		datastream_mimetype_matches?(fedora_obj, 'content', *patterns)
	end
end
