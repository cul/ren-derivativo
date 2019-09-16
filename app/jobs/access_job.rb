class AccessJob < ApplicationJob
  queue_as :access

  def perform(*args)
    # Do something later
  end
end
