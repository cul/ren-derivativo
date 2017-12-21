class ExtractFulltextJob
  @queue = Derivativo::Queue::TEXT_EXTRACTION_LOW # This is the default queue for this job

  def self.perform(id, queue_time_string=Time.now.to_s)
		ExtractableTextResource.new(id).extract_fulltext_if_not_exist
  end
end
