class PrepareAccessBaseRasterJob < ApplicationJob
  queue_as Derivativo::Queues::PREPARE_ACCESS_BASE_RASTER

  # Evaluates the given resource and queues a new GenerateAccessBaseRasterJob on the appropriate
  # queue, based on resource type.
  # If raster_opts is given a value of nil, specific raster generation will be skipped
  # and only access and base generation will occur.
  def perform(identifier:, raster_opts:)
    # resource = Resource.new(identifier)

    # TODO:
    # 1: Identifier file type
    # 2: Queue job on correct queue

    GenerateAccessBaseRasterJob.set(queue: Derivativo::Queues::GENERATE_ACCESS_BASE_RASTER_FOR_TYPE_ANY).perform_later(
      identifier: identifier,
      raster_opts: raster_opts,
    )
  end
end
