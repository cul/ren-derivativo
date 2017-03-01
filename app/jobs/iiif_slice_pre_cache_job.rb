class IiifSlicePreCacheJob
  @queue = Derivativo::Queue::LOW # This is the default queue for this job

  def self.perform(opts, queue_time_string=Time.now.to_s)
		opts = HashWithIndifferentAccess.new(opts)
		Iiif.new(opts).create_iiif_slice_pre_cache
  end
end