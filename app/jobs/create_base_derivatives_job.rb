class CreateBaseDerivativesJob
  @queue = Derivativo::Queue::LOW # This is the default queue for this job

  def self.perform(id, queue_time_string=Time.now.to_s)
		IiifResource.new({id: id}).create_base_derivatives_if_not_exist
  end
end