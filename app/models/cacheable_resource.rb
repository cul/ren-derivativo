class CacheableResource
  attr_reader :id, :fedora_object

  ACCESS_DATASTREAM_NAME = 'access'
  ONSITE_RESTRICTION_LITERAL_VALUE = 'onsite restriction'

  def initialize(id_or_fedora_obj)

    raise 'Not supposed to instantiate abstract class ' + self.class.name if self.class.name == 'MediaResource'

    if id_or_fedora_obj.is_a?(String)
      @id = id_or_fedora_obj
      @fedora_object = ActiveFedora::Base.find(self.id)
    elsif id_or_fedora_obj.is_a?(ActiveFedora::Base)
      @id = id_or_fedora_obj.pid
      @fedora_object = id_or_fedora_obj
    end
  end
end