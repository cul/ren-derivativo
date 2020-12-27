# frozen_string_literal: true

module ResourceRequestJobs
  class PosterForPdfJob < ApplicationJob
    include ResourceRequestJobs::ProcessingHelpers

    queue_as :resource_request_poster_for_pdf

    # Creates a poster for a pdf resource.
    def perform(resource_request_id:, digital_object_uid:, src_file_location:, options: {})
      with_shared_error_handling(resource_request_id) do
        Rails.logger.info("Running #{self.class.name} job for resource request #{resource_request_id}")
        validate_options!(options)

        Hyacinth::Client.instance.resource_request_in_progress!(resource_request_id)
        generate_and_upload(src_file_location, digital_object_uid, options)
        Hyacinth::Client.instance.resource_request_success!(resource_request_id)
      end
    end

    # Validates the given options, raising an Derivativo::Exceptions::OptionError if the options are invalid
    def validate_options!(options)
      validate_required_option!(options, 'format', ['png', 'jpg'])
      true
    end

    private

      def generate_and_upload(src_file_location, digital_object_uid, options)
        file_prefix = 'poster'
        file_suffix = ".#{options['format']}"
        # Reserve file in working directory to avoid name collisions with concurrent processes.
        Derivativo::FileHelper.working_directory_temp_file(file_prefix, file_suffix) do |dst_file|
          # TODO: Maybe one day, add support for specific PDF page selection
          Derivativo::Conversion.pdf_to_image(
            src_file_path: Derivativo::FileHelper.file_location_to_file_path(src_file_location),
            dst_file_path: dst_file.path
          )

          # Upload file to Hyacinth's active storage
          signed_id = Hyacinth::Client.instance.upload_file_to_active_storage(dst_file.path, file_prefix + file_suffix)

          # Update the Hyacinth resource via graphql
          Hyacinth::Client.instance.create_resource(digital_object_uid, 'poster', "blob://#{signed_id}")
        end
      end
  end
end
