# frozen_string_literal: true

module ResourceRequestJobs
  class AccessForTextOrOfficeDocumentJob < ApplicationJob
    include ResourceRequestJobs::ProcessingHelpers

    queue_as :resource_request_access_for_text_or_office_document

    # Creates an access copy for a text or office_document resource.
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
      validate_required_option!(options, 'format', ['pdf'])
      true
    end

    private

      def generate_and_upload(src_file_location, digital_object_uid, options)
        file_prefix = 'access'
        file_suffix = ".#{options['format']}"

        # Reserve file in working directory to avoid name collisions with concurrent processes.
        Derivativo::FileHelper.working_directory_temp_file(file_prefix, file_suffix) do |dst_file|
          Derivativo::Conversion.text_or_office_document_to_pdf(src_file_path: Derivativo::FileHelper.file_location_to_file_path(src_file_location), dst_file_path: dst_file.path)

          # Upload file to Hyacinth's active storage
          signed_id = Hyacinth::Client.instance.upload_file_to_active_storage(dst_file.path, file_prefix + file_suffix)

          # Update the Hyacinth resource via graphql
          Hyacinth::Client.instance.create_resource(digital_object_uid, 'access', "blob://#{signed_id}")
        end
      end
  end
end
