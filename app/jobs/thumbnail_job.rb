class ThumbnailJob < ApplicationJob
  queue_as :thumbnail

  def perform(*args)
    # Do something later
  end
end
