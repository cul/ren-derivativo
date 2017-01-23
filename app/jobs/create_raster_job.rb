class CreateRasterJob
  @queue = Derivativo::Queue::CREATE_AND_STORE # This is the default queue for this job

  def self.perform(opts, queue_time_string=Time.now.to_s)
		opts = HashWithIndifferentAccess.new(opts)
		Iiif.new(opts).create_raster
  end
end