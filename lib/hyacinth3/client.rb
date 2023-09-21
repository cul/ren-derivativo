# frozen_string_literal: true

# This class is commented out for now because the Hyacinth3::Client was originally written with
# Faraday 1.x and needs to be updated for Faraday 2.x.  Also, the method of sending derivatives
# to Hyacinth 3 is likely to change once Hyacinth 3 is connected to Derivativo 3 (as opposed to
# Derivativo 2, which worked in a different way.

module Hyacinth3
  class Client
    # ACTIVE_STORAGE_UPLOAD_SUCCESS_STATUS = 204

    # def self.instance
    #   @instance ||= self.new(**HYACINTH)
    # end

    # def initialize(url:, email:, password:) # TODO: Add support for request_timeout
    #   @conn = ::Faraday.new(url: self.url) do |f|
    #     f.response :json # decode response bodies as JSON
    #     f.adapter :net_http # Use the Net::HTTP adapter
    #     f.request :authorization, :basic, email, password
    #     f.request :multipart
    #   end
    # end

    # def create_resource(digital_object_uid, resource_name, file_location)
    #   query = <<~GQL
    #     mutation ($input: CreateResourceInput!) {
    #       createResource(input: $input) {
    #         digitalObject {
    #           id
    #         }
    #         userErrors {
    #           message
    #         }
    #       }
    #     }
    #   GQL

    #   variables = {
    #     input: {
    #       id: digital_object_uid,
    #       resourceName: resource_name,
    #       fileLocation: file_location
    #     }
    #   }

    #   graphql(query, variables).tap do |gql_response|
    #     gql_response['errors'].tap do |errors|
    #       raise Hyacinth::Client::Exceptions::UnexpectedResponse, "Errors encountered during create_resource attempt: #{errors.inspect}" if errors.present?
    #     end
    #     gql_response.dig('data', 'createResource', 'userErrors').tap do |user_errors|
    #       raise Hyacinth::Client::Exceptions::UnexpectedResponse, "Errors encountered during create_resource attempt: #{user_errors.inspect}" if user_errors.present?
    #     end
    #   end

    #   true
    # end

    # # @return An Active Storage signed id upon successful upload, or nil if the upload fails.
    # def upload_file_to_active_storage(file_path, original_filename)
    #   File.open(file_path, 'rb') do |file|
    #     # The line below does a buffered file read for low memory usage, and is the same method
    #     # used for checksum calculation as ActiveStorage (to ensure matching checksum validation).
    #     file_checksum = Digest::MD5.file(file_path).base64digest

    #     mime_type = BestType.mime_type.for_file_name(file_path)
    #     file_size = file.size

    #     active_storage_blob_creation_response = @conn.post('/api/v1/uploads') do |req|
    #       req.params['blob'] = {
    #         filename: original_filename,
    #         byte_size: file_size,
    #         checksum: file_checksum,
    #         content_type: mime_type
    #       }
    #     end

    #     signed_id, direct_upload_data = JSON.parse(active_storage_blob_creation_response.body).values_at('signed_id', 'direct_upload')

    #     active_storage_upload_response = @conn.put(direct_upload_data['url']) do |req|
    #       # Required for streaming the upload
    #       req.headers.merge!('Transfer-Encoding' => 'chunked', 'Content-Length' => file_size.to_s)

    #       # Direct upload data includes headers that should be sent in upload request (e.g. Content-Type)
    #       req.headers.merge!(direct_upload_data['headers'])

    #       # Actual request body IS the file content
    #       req.body = Faraday::FilePart.new(file.path, mime_type)
    #     end

    #     if active_storage_upload_response.status != ACTIVE_STORAGE_UPLOAD_SUCCESS_STATUS
    #       raise Hyacinth::Client::Exceptions::UnexpectedResponse, "Expected #{ACTIVE_STORAGE_UPLOAD_SUCCESS_STATUS} status from Hyacinth for upload, but got #{active_storage_upload_response.status}"
    #     end

    #     signed_id
    #   end
    # end

    # def resource_request_success!(resource_request_id)
    #   update_resource_request(resource_request_id: resource_request_id, status: 'success')
    # end

    # def resource_request_failure!(resource_request_id, processing_errors)
    #   update_resource_request(resource_request_id: resource_request_id, status: 'failure', processing_errors: processing_errors)
    # end

    # def resource_request_in_progress!(resource_request_id)
    #   update_resource_request(resource_request_id: resource_request_id, status: 'in_progress')
    # end

    # def update_resource_request(resource_request_id:, status:, processing_errors: [])
    #   query = <<~GQL
    #     mutation ($input: UpdateResourceRequestInput!) {
    #       updateResourceRequest(input: $input) {
    #         resourceRequest {
    #           id
    #         }
    #       }
    #     }
    #   GQL

    #   variables = {
    #     input: {
    #       id: resource_request_id,
    #       status: status,
    #       processingErrors: processing_errors
    #     }
    #   }

    #   graphql(query, variables).tap do |gql_response|
    #     gql_response['errors'].tap do |errors|
    #       raise Hyacinth::Client::Exceptions::UnexpectedResponse, "Errors encountered during update_resource_request attempt: #{errors.inspect}" if errors.present?
    #     end
    #   end

    #   true
    # end

    # def update_featured_thumbnail_region(digital_object_uid, featured_thumbnail_region)
    #   query = <<~GQL
    #     mutation ($input: UpdateFeaturedThumbnailRegionInput!) {
    #       updateFeaturedThumbnailRegion(input: $input) {
    #         digitalObject {
    #           id
    #         }
    #         userErrors {
    #           message
    #         }
    #       }
    #     }
    #   GQL

    #   variables = {
    #     input: {
    #       id: digital_object_uid,
    #       featuredThumbnailRegion: featured_thumbnail_region
    #     }
    #   }

    #   graphql(query, variables).tap do |gql_response|
    #     gql_response['errors'].tap do |errors|
    #       raise Hyacinth::Client::Exceptions::UnexpectedResponse, "Errors encountered during update_featured_thumbnail_region attempt: #{errors.inspect}" if errors.present?
    #     end
    #     gql_response.dig('data', 'updateFeaturedThumbnailRegion', 'userErrors').tap do |user_errors|
    #       raise Hyacinth::Client::Exceptions::UnexpectedResponse, "Errors encountered during create_resource attempt: #{user_errors.inspect}" if user_errors.present?
    #     end
    #   end

    #   true
    # end

    # def graphql(query, variables = {})
    #   params = { query: query }
    #   params[:variables] = variables.is_a?(Hash) ? variables.to_json : variables unless variables.blank?

    #   response = @conn.post('/graphql') do |req|
    #     req.params = params
    #   end

    #   JSON.parse(response.body)
    # end

    # module Exceptions
    #   class Error < StandardError; end
    #   class UnexpectedResponse < Error; end
    # end

    # # Note: The method below is not currently in use, but may be useful later.
    # #
    # # This method downloads a file with the appropriate extension for the downloaded resource, which
    # # ends up being important for file type detection in the conversion libraries we use.
    # # Even if we have access to the Hyacinth filesystem, we can't rename one of Hyacinth's files
    # # and we also can't guarantee that we'll have permission to read it (because Hyacinth may run
    # # as a different user than Derivativo).  Also, if Hyacinth one day stores file in the cloud
    # # instead of on disk, a download from Hyacinth may be the only way for Derivativo to obtain
    # # a copy of the source file, so download source files makes sense for the future too.
    # #
    # # Theoretically, if we really wanted to, we could add an extra parameter to this method
    # # to indicate that Hyacinth and Derivativo are on the same filesystem, and we could copy
    # # (and rename) the file instead of downloading it because it would be faster, but could still
    # # potentially run into the permission issues mentioned above, and this method won't work if
    # # Hyacinth eventually stores resources in the cloud.
    # # def with_resource_download(digital_object_uid, resource_name)
    # #   # Get filename from response headers
    # #   # TODO: Determine if it's possible to do this as part of the second http request below.  The
    # #   # problem right now is that we want to create a tempfile that has the correct file extension,
    # #   # so we need to know the extension before we create a tempfile.
    # #   # response = @conn.head("/api/v1/downloads/digital_object/#{digital_object_uid}/#{resource_name}")

    # #   Derivativo::FileHelper.working_directory_temp_file('download', '.temp') do |temp_download_file|
    # #     response = @conn.get("/api/v1/downloads/digital_object/#{digital_object_uid}/#{resource_name}") do |req|
    # #       req.options.on_data = proc do |chunk, _overall_received_bytes|
    # #         temp_download_file.write(chunk)
    # #       end
    # #     end

    # #     # Determine the correct file extension from the Content-Disposition header, and then rename
    # #     # the downloaded file, using our tempfile generation method to guarantee a unique filename.
    # #     file_suffix = File.extname(response.headers['Content-Disposition'].sub(/^.+filename=/, ''))
    # #     Derivativo::FileHelper.working_directory_temp_file('download', file_suffix) do |renamed_temp_file|
    # #       File.rename(temp_download_file, renamed_temp_file.path)
    # #       # After the rename, the renamed_temp_file variable still references an empty temp file, so
    # #       # we'll actually be yielding a new file to the caller.
    # #       File.open(renamed_temp_file.path, 'rb') do |file_to_yield|
    # #         yield file_to_yield
    # #       end
    # #     ensure
    # #       # Our new file might end up being cleaned up by the tempfile, since they both have
    # #       # the same path, but we don't want to take any chances on differences across operating
    # #       # systems that use a file inode pointer rather than a file path, so we'll make sure to
    # #       # unlink the file at the renamed_temp_file once we're done with it. This won't cause
    # #       # any problems for the surrounding tempfile block.
    # #       File.unlink(renamed_temp_file.path)
    # #     end
    # #   end
    # # end
  end
end
