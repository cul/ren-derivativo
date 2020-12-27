# frozen_string_literal: true

module ResourceRequestJobs
  class FeaturedThumbnailRegionJob < ApplicationJob
    include ResourceRequestJobs::ProcessingHelpers

    queue_as :resource_request_featured_thumbnail_region

    # Extracts text from the given resource.
    def perform(resource_request_id:, digital_object_uid:, src_file_location:, options: {})
      with_shared_error_handling(resource_request_id) do
        Rails.logger.info("Running #{self.class.name} job for resource request #{resource_request_id}")
        validate_options!(options)
        Hyacinth::Client.instance.resource_request_in_progress!(resource_request_id)

        featured_thumbnail_region = Derivativo::ImageAnalysis.featured_thumbnail_region(
          src_file_path: Derivativo::FileHelper.file_location_to_file_path(src_file_location)
        )

        Hyacinth::Client.instance.update_featured_thumbnail_region(digital_object_uid, featured_thumbnail_region)
        Hyacinth::Client.instance.resource_request_success!(resource_request_id)
      end
    end

    # Validates the given options, raising an Derivativo::Exceptions::OptionError if the options are invalid
    def validate_options!(_options)
      # The featured thumbnail region job doesn't support any options at this time
      true
    end
  end
end
