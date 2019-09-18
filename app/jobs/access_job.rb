class AccessJob
  @queue = :access

  def self.perform(*args)
    Rails.logger.info "Running access job with args: #{args.inspect}"
  end
end
