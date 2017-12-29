class CacheableResource
  attr_reader :id

  ACCESS_DATASTREAM_NAME = 'access'
  ONSITE_RESTRICTION_LITERAL_VALUE = 'onsite restriction'

  DOI_PATTERN = /^10\.[^\/]+\/[^\/]+$/
  PID_PATTERN = /^[A-Za-z0-9]+:[A-Za-z0-9]+$/
  DOI_PREDICATE = "http://purl.org/ontology/bibo/doi"
  def initialize(id_or_fedora_obj)

    raise 'Not supposed to instantiate abstract class ' + self.class.name if self.class.name == 'MediaResource'

    if id_or_fedora_obj.is_a?(String)
      @id = id_or_fedora_obj
    elsif id_or_fedora_obj.is_a?(ActiveFedora::Base)
      @id = id_or_fedora_obj.pid
      @fedora_object = id_or_fedora_obj
    end
  end
  def fedora_object
    @fedora_object ||= begin
      if self.id =~ DOI_PATTERN
        # look up the DOI in the RISearch
        query = "select $pid from <#ri> where $pid <#{DOI_PREDICATE}> <doi:#{self.id}>"
        puts query
        search_response = 
          JSON(Cul::Hydra::Fedora.repository.find_by_itql(query,
            :type => 'tuples',
            :format => 'json',
            :limit => '',
            :stream => 'on'))
        pid = search_response['results'][0]['pid']
        pid = pid.split('/')[-1] if pid
        ActiveFedora::Base.find(pid) if pid
      else
        ActiveFedora::Base.find(self.id)
      end
    end
  end
end