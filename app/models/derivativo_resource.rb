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
    FileUtils.rm_rf(Derivativo::CachePathBuilder.path_for_id(self.id))
    
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
    end
    
  end
end