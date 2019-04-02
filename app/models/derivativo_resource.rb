# Abstraction layer around cache generation and clearing.
# Currently only for IIIF, but could be for text and video later on.
class DerivativoResource

  attr_reader :id

  def initialize(id_or_fedora_obj)
    if id_or_fedora_obj.is_a?(String)
      @id = id_or_fedora_obj
    elsif id_or_fedora_obj.is_a?(ActiveFedora::Base)
      @id = id_or_fedora_obj.pid
      @fedora_object = id_or_fedora_obj
    end
  end

  def fedora_object
    begin
      @fedora_object ||= ActiveFedora::Base.find(self.id)
    rescue ActiveFedora::ObjectNotFoundError
      raise Derivativo::Exceptions::ResourceNotFound unless @fedora_obj.present?
    end
  end

  def clear_cache
    # Completely destroy cache directory for this object
    FileUtils.rm_rf(Derivativo::CachePathBuilder.base_path_for_id(self.id))
    FileUtils.rm_rf(Derivativo::CachePathBuilder.iiif_path_for_id(self.id))
    # Also destroy media access copy if this is audiovisual material
    if Derivativo::FedoraObjectTypeCheck.is_generic_resource_audio_or_video?(fedora_object)
      FileUtils.rm_rf(Derivativo::CachePathBuilder.media_path_for_id(self.id))
    end

    if Derivativo::FedoraObjectTypeCheck.is_text_extractable_generic_resource?(fedora_object)
      pdf_access_copy_path = File.join(
        Derivativo::CachePathBuilder.media_path_for_id(self.id), DERIVATIVO['extractabletextresource_access_copy_settings']['filename']
      )
      FileUtils.rm_rf(pdf_access_copy_path)
    end

    clear_cachable_properties
  end

  def clear_cachable_properties
    # Clear IIIF cached properties if this is a rasterable generic resource
    # If it's not a rasterable generic resource, this line won't do anything bad,
    # so it's fine to call without checking whether the id is valid. This makes
    # cache clearing operations faster.
    IiifResource.new(id: self.id).clear_cachable_properties
  end

  def generate_cache(queue_long_jobs = DERIVATIVO[:queue_long_jobs], route_helper = nil)
    # If this is a rasterable IIIF generic resource, do IIIF caching
    if Derivativo::FedoraObjectTypeCheck.is_rasterable_generic_resource?(fedora_object)
      iiif = IiifResource.new(id: self.id)
      if queue_long_jobs
        Rails.logger.debug "Queueing derivative generation for #{self.id}"
        iiif.queue_base_derivatives_if_not_exist
      else
        Rails.logger.debug "Generating derivatives for #{self.id} if not exist"
        iiif.create_base_derivatives_if_not_exist
      end
    end

    if Derivativo::FedoraObjectTypeCheck.is_generic_resource_audio?(fedora_object)
      media_model = Audio
    elsif Derivativo::FedoraObjectTypeCheck.is_generic_resource_video?(fedora_object)
      media_model = Video
    elsif Derivativo::FedoraObjectTypeCheck.is_text_extractable_generic_resource?(fedora_object)
      media_model = ExtractableTextResource
    end

    if media_model
      media = media_model.new(fedora_object)
      if queue_long_jobs
        media.queue_access_copy_generation
        media.queue_fulltext_extraction if media.is_a? ExtractableTextResource
      else
        media.create_access_copy_if_not_exist
        media.extract_fulltext_if_not_exist if media.is_a? ExtractableTextResource
      end
    end

    unless Derivativo::FedoraObjectTypeCheck.is_generic_resource?(fedora_object)
      manifest = Manifest.new(fedora_object, route_helper)
      if queue_long_jobs
        manifest.queue_manifest_generation
      else
        manifest.create_manifest_if_not_exist
      end
    end
  end
end
