#require "open-uri"

class CreateBaseDerivativesJob
  @queue = Derivativo::Queue::CREATE_AND_STORE # This is the default queue for this job

  def self.perform(id, queue_time_string=Time.now.to_s)
		Iiif.new({id: id}).create_and_store
  end
end