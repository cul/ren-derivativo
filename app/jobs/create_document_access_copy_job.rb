class CreateDocumentAccessCopyJob
	@queue = Derivativo::Queue::LOW # This is the default queue for this job

	def self.perform(id, queue_time_string=Time.now.to_s)
		ExtractableTextResource.new(id).create_access_copy_if_not_exist
	end
end
