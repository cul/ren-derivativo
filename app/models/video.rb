class Video < MediaResource
  include Derivativo::FfmpegDerivatives
  def queue_access_copy_generation(queue_name = Derivativo::Queue::MEDIA_CONVERSION_LOW)
    Resque.enqueue_to(queue_name, CreateVideoAccessCopyJob, id, Time.now.to_s)
  end

  def self.duration_for(video_path)
  end
end
