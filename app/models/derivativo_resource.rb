# Abstraction layer around cache generation and clearing.
# Currently only for IIIF, but could be for text and video later on.
class DerivativoResource

  attr_reader :id

  def initialize(id)
    @id = id
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

    # For audio and video resources, we run a delete command in both the public
    # and restricted directories so that if the restriction property has been
    # changed since original derivative generation, we properly delete all copies
    object_project_pid = fedora_object.relationships(:is_constituent_of).first.gsub('info:fedora/', '')
    if Derivativo::FedoraObjectTypeCheck.is_generic_resource_audio?(fedora_object)
      FileUtils.rm_rf(Derivativo::CachePathBuilder.media_path_for_id('audio', true, object_project_pid, self.id))
      FileUtils.rm_rf(Derivativo::CachePathBuilder.media_path_for_id('audio', false, object_project_pid, self.id))
    elsif Derivativo::FedoraObjectTypeCheck.is_generic_resource_video?(fedora_object)
      FileUtils.rm_rf(Derivativo::CachePathBuilder.media_path_for_id('video', true, object_project_pid, self.id))
      FileUtils.rm_rf(Derivativo::CachePathBuilder.media_path_for_id('video', false, object_project_pid, self.id))
    end

    clear_cachable_properties
  end

  def clear_cachable_properties
    # Clear IIIF cached properties if this is a rasterable generic resource
    # If it's not a rasterable generic resource, this line won't do anything bad,
    # so it's fine to call without checking whether the id is valid. This makes
    # cache clearing operations faster.
    Iiif.new(id: self.id).clear_cachable_properties
  end

  def generate_cache
    # If this is a rasterable IIIF generic resource, do IIIF caching
    if Derivativo::FedoraObjectTypeCheck.is_rasterable_generic_resource?(fedora_object)
      iiif = Iiif.new(id: self.id)
      if DERIVATIVO[:queue_long_jobs]
        Rails.logger.debug "Queueing derivative generation for #{self.id}"
        iiif.queue_base_derivatives_if_not_exist
      else
        Rails.logger.debug "Generating derivatives for #{self.id} if not exist"
        begin
          iiif.create_base_derivatives_if_not_exist
        rescue
          render status: :not_found, json: { "error" => "Resource not found with id: #{self.id}" }
          return
        end
      end
    elsif Derivativo::FedoraObjectTypeCheck.is_generic_resource_audio?(fedora_object)
      audio = Audio.new(fedora_object)
      if DERIVATIVO[:queue_long_jobs]
        audio.queue_access_copy_generation
      else
        audio.create_access_copy_if_not_exist
      end
    elsif Derivativo::FedoraObjectTypeCheck.is_generic_resource_video?(fedora_object)
      video = Video.new(fedora_object)
      if DERIVATIVO[:queue_long_jobs]
        video.queue_access_copy_generation
      else
        video.create_access_copy_if_not_exist
      end
    end

  end
end
