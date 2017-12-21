class ExtractableTextResource
  attr_reader :id, :fedora_object

  FULLTEXT_DATASTREAM_NAME = 'fulltext'
  EXTRACTED_TEXT_MIME_TYPE = 'text/plain'
  FULLTEXT_DATASTREAM_PROCESSING_PLACEHOLDER_TEXT = ''

  def initialize(id_or_fedora_obj)
    if id_or_fedora_obj.is_a?(String)
      @id = id_or_fedora_obj
      @fedora_object = ActiveFedora::Base.find(self.id)
    elsif id_or_fedora_obj.is_a?(ActiveFedora::Base)
      @id = id_or_fedora_obj.pid
      @fedora_object = id_or_fedora_obj
    end

    raise "Error: Non-text-extractable resource" unless Derivativo::FedoraObjectTypeCheck.is_text_extractable_generic_resource?(@fedora_object)
  end

  def queue_fulltext_extraction(queue_name = Derivativo::Queue::TEXT_EXTRACTION_LOW)
    Resque.enqueue_to(queue_name, ExtractFulltextJob, @id, Time.now.to_s)
  end

  def extract_fulltext_if_not_exist
    # Return if Fedora object already has a fulltext datastream
    fulltext_ds = fedora_object.datastreams[FULLTEXT_DATASTREAM_NAME]
    return if fulltext_ds.present?
    fulltext_ds = fedora_object.create_datastream(
      ActiveFedora::Datastream,
      FULLTEXT_DATASTREAM_NAME,
      :controlGroup => 'M',
      :mimeType => EXTRACTED_TEXT_MIME_TYPE,
      :dsLabel => FULLTEXT_DATASTREAM_NAME,
      :versionable => false
    )
    fedora_object.add_datastream(fulltext_ds)
    # Now begin processing
    fedora_object.with_ds_resource('content', (! DERIVATIVO['no_mount']) ) do |file_path|
      fulltext_ds.content = Derivativo::TikaTextExtractor.extract_text_from_file(file_path)
      fedora_object.save(update_index: false)
    end

    fulltext_ds
  end
end
