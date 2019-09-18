class ThumbnailJob
  @queue = :thumbnail

  def self.perform(*args)
    Rails.logger.info "Running thumbnail job with args: #{args.inspect}"
  end
end
