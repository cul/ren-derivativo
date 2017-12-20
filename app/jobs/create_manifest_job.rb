class CreateManifestJob
  @queue = Derivativo::Queue::HIGH # This is the default queue for this job

  def self.perform(id, queue_time_string=Time.now.to_s)
    Manifest.new(id).create_manifest_if_not_exist
  end
end