class CacheableResource
  attr_reader :id

  ACCESS_DATASTREAM_NAME = 'access'

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
  def fedora_pid
    @fedora_pid ||= begin
      if self.id =~ DOI_PATTERN
        # look up the DOI in the RISearch
        query = "select $pid from <#ri> where $pid <#{DOI_PREDICATE}> <doi:#{self.id}>"
        search_response =
          JSON(Cul::Hydra::Fedora.repository.find_by_itql(query,
            :type => 'tuples',
            :format => 'json',
            :limit => '',
            :stream => 'on'))
        result = search_response['results'][0] || {}
        pid = result['pid']
        pid.split('/')[-1] if pid
      else
        self.id
      end
    end
  end
  def doi
    @doi ||= begin
      if self.id =~ DOI_PATTERN
        self.id
      else
        # look up the DOI in the RISearch
        query = "select $doi from <#ri> where <info:fedora/#{self.id}> <#{DOI_PREDICATE}> $doi"
        search_response =
          JSON(Cul::Hydra::Fedora.repository.find_by_itql(query,
            :type => 'tuples',
            :format => 'json',
            :limit => '',
            :stream => 'on'))
        result = search_response['results'][0] || {}
        doi = result['doi']
        doi.sub(/^doi:/,'') if doi
      end
    end
  end
  def fedora_object
    @fedora_object ||= ActiveFedora::Base.find(fedora_pid)
  end
end
