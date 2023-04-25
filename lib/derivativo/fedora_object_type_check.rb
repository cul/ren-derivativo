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
		return false unless is_generic_resource?(fedora_obj)

		detected_dc_type = BestType.dc_type.for_mime_type(datastream_mime_type(fedora_obj, dsid))
		return true if detected_dc_type == 'Sound'
		return true if fedora_obj.datastreams['DC'].dc_type.include?('Sound')
		return true if detected_dc_type == 'MovingImage' && is_media_file_with_audio_track_only?(fedora_obj)

		false
	end

	def self.is_media_file_with_audio_track_only?(fedora_obj)
		# Some videos only contain audio tracks (like 3gp files), so this method checks for that.
		ds_location = (fedora_obj.datastreams['service']&.dsLocation || fedora_obj.datastreams['content']&.dsLocation)
		return false if ds_location.blank?
    source_file_location = Addressable::URI.unencode(ds_location).gsub(/^file:/, '')
    movie = FFMPEG::Movie.new(source_file_location)
    return true if movie.audio_stream.present? && movie.video_stream.blank?
		false
	end

	def self.is_generic_resource_video?(fedora_obj, dsid='content')
		is_generic_resource?(fedora_obj) && BestType.dc_type.for_mime_type(datastream_mime_type(fedora_obj, dsid)) == 'MovingImage'
	end

	def self.is_generic_resource_rasterable_video?(fedora_obj, dsid='content')
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
