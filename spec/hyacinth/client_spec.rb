# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyacinth::Client do
  let(:valid_client_args) do
    {
      url: 'https://www.hyacinth-domain.com:1234',
      email: 'derivativo@library.columbia.edu',
      password: 'test',
      request_timeout: 123
    }
  end
  let(:instance) { described_class.new(valid_client_args) }
  let(:internal_conn) { instance.instance_variable_get('@conn') }
  let(:expected_auth_header_value) { 'Basic ZGVyaXZhdGl2b0BsaWJyYXJ5LmNvbHVtYmlhLmVkdTp0ZXN0' }

  describe "new instance" do
    it 'is successfully created when valid arguments are given' do
      expect(instance).to be_a(described_class)
    end
    it 'correctly sets up the internal Faraday connection object' do
      internal_conn.url_prefix.tap do |uri|
        expect(uri.host).to eq('www.hyacinth-domain.com')
        expect(uri.port).to eq(1234)
      end
      expect(internal_conn.headers[Faraday::Request::Authorization::KEY]).to eq(expected_auth_header_value)
    end
  end

  describe '#create_resource' do
    let(:digital_object_uid) { '1234-5678' }
    let(:resource_name) { 'access' }
    let(:file_location) { '/path/to/resource.txt' }

    let(:expected_variables) do
      {
        input: {
          id: digital_object_uid,
          resourceName: resource_name,
          fileLocation: file_location
        }
      }
    end

    let(:expected_gql_query) do
      <<~GQL
        mutation ($input: CreateResourceInput!) {
          createResource(input: $input) {
            digitalObject {
              id
            }
            userErrors {
              message
            }
          }
        }
      GQL
    end

    let(:gql_response_body) do
      { data: { createResource: { digitalObject: { id: digital_object_uid }, userErrors: [] } } }.to_json
    end

    before do
      stub_request(:post, "#{valid_client_args[:url]}/graphql").with(query: hash_including({})).to_return(status: 200, body: gql_response_body)
      expect(instance).to receive(:graphql).with(expected_gql_query, expected_variables).and_call_original
    end

    it 'performs the expected request and returns true upon success' do
      expect(instance.create_resource(digital_object_uid, resource_name, file_location)).to eq(true)
      expect(
        a_request(:post, "#{valid_client_args[:url]}/graphql").with(
          query: { query: expected_gql_query, variables: expected_variables.to_json },
          headers: { Faraday::Request::Authorization::KEY => expected_auth_header_value }
        )
      ).to have_been_made.once
    end

    context 'when a top level graphql error is returned' do
      let(:gql_response_body) do
        { errors: [{ path: ['path'], message: 'This is the message' }] }.to_json
      end
      it 'raises an exception' do
        expect { instance.create_resource(digital_object_uid, resource_name, file_location) }.to raise_error(Hyacinth::Client::Exceptions::UnexpectedResponse)
      end
    end

    context 'when a user error is returned in the data' do
      let(:gql_response_body) do
        { data: { createResource: { digitalObject: nil, userErrors: [{ message: 'This is a user error message.' }] } } }.to_json
      end
      it 'raises an exception' do
        expect { instance.create_resource(digital_object_uid, resource_name, file_location) }.to raise_error(Hyacinth::Client::Exceptions::UnexpectedResponse)
      end
    end
  end

  describe '#upload_file_to_active_storage' do
    let(:file_path) { file_fixture('text.txt').realpath.to_s }
    let(:original_filename) { File.basename(file_path) }
    let(:file_size) { File.size(file_path) }
    let(:file_checksum) { 'KqjpIsPYZxaZ2qdxRTDKvw==' }
    let(:mime_type) { 'text/plain' }

    let(:expected_blob_params) do
      {
        filename: original_filename,
        byte_size: file_size,
        checksum: file_checksum,
        content_type: mime_type
      }
    end
    let(:expected_signed_id) { 'abc123' }
    let(:active_storage_blob_creation_response) do
      {
        'id' => 2,
        'filename' => original_filename,
        'content_type' => mime_type,
        'byte_size' => file_size,
        'checksum' => file_checksum,
        'signed_id' => expected_signed_id,
        'direct_upload' => {
          'url' => "#{valid_client_args[:url]}/rails/active_storage/disk/abcdefg",
          'headers' => { 'Content-Type' => 'text/plain' }
        }
      }
    end

    let(:direct_upload_response_status) { 204 } # successful upload

    before do
      stub_request(:post, "#{valid_client_args[:url]}/api/v1/uploads").with(query: hash_including({})).to_return(status: 200, body: active_storage_blob_creation_response.to_json)
      stub_request(:put, active_storage_blob_creation_response['direct_upload']['url']).to_return(status: direct_upload_response_status)
    end

    context 'a successful upload' do
      after do
        expect(
          a_request(:post, "#{valid_client_args[:url]}/api/v1/uploads").with(
            query: { blob: expected_blob_params },
            headers: { Faraday::Request::Authorization::KEY => expected_auth_header_value }
          )
        ).to have_been_made.once
        expect(
          a_request(:put, active_storage_blob_creation_response['direct_upload']['url']).with(
            headers: {
              Faraday::Request::Authorization::KEY => expected_auth_header_value,
              'Transfer-Encoding' => 'chunked',
              'Content-Length' => file_size
            },
            body: File.read(file_path)
          )
        ).to have_been_made.once
      end
      it 'works as expected' do
        expect(instance.upload_file_to_active_storage(file_path, original_filename)).to eq(expected_signed_id)
      end
    end

    context 'the active storage direct upload response is not a 204' do
      let(:direct_upload_response_status) { 500 }
      it 'raises an error' do
        expect { instance.upload_file_to_active_storage(file_path, original_filename) }.to raise_error(Hyacinth::Client::Exceptions::UnexpectedResponse)
      end
    end
  end

  describe '#update_resource_request' do
    let(:resource_request_id) { 1 }
    let(:status) { 'failure' }
    let(:processing_errors) { ['error 1', 'error 2', 'error 3'] }

    let(:expected_variables) do
      {
        input: {
          id: resource_request_id,
          status: status,
          processingErrors: processing_errors
        }
      }
    end

    let(:expected_gql_query) do
      <<~GQL
        mutation ($input: UpdateResourceRequestInput!) {
          updateResourceRequest(input: $input) {
            resourceRequest {
              id
            }
          }
        }
      GQL
    end

    let(:gql_response_body) do
      { data: { updateResourceRequest: { resourceRequest: { id: resource_request_id } } } }.to_json
    end

    before do
      stub_request(:post, "#{valid_client_args[:url]}/graphql").with(query: hash_including({})).to_return(status: 200, body: gql_response_body)
      expect(instance).to receive(:graphql).with(expected_gql_query, expected_variables).and_call_original
    end

    it 'performs the expected request and returns true upon success' do
      expect(instance.update_resource_request(resource_request_id: resource_request_id, status: status, processing_errors: processing_errors)).to eq(true)
      expect(
        a_request(:post, "#{valid_client_args[:url]}/graphql").with(
          query: { query: expected_gql_query, variables: expected_variables.to_json },
          headers: { Faraday::Request::Authorization::KEY => expected_auth_header_value }
        )
      ).to have_been_made.once
    end

    context 'when no value is provided to the method' do
      let(:expected_variables) do
        {
          input: {
            id: resource_request_id,
            status: status,
            processingErrors: []
          }
        }
      end
      it 'provides an empty array to the processingErrors variable' do
        expect(instance.update_resource_request(resource_request_id: resource_request_id, status: status)).to eq(true)
        expect(
          a_request(:post, "#{valid_client_args[:url]}/graphql").with(
            query: { query: expected_gql_query, variables: expected_variables.to_json }, headers: { Faraday::Request::Authorization::KEY => expected_auth_header_value }
          )
        ).to have_been_made.once
      end
    end

    context 'when a top level graphql error is returned' do
      let(:gql_response_body) do
        { errors: [{ path: ['path'], message: 'This is the message' }] }.to_json
      end
      it 'raises an exception' do
        expect {
          instance.update_resource_request(resource_request_id: resource_request_id, status: status, processing_errors: processing_errors)
        }.to raise_error(Hyacinth::Client::Exceptions::UnexpectedResponse)
      end
    end
  end

  describe '#resource_request_success!' do
    let(:resource_request_id) { 1 }

    it 'runs as expected' do
      expect(instance).to receive(:update_resource_request).with(resource_request_id: resource_request_id, status: 'success')
      instance.resource_request_success!(resource_request_id)
    end
  end

  describe '#resource_request_failure!' do
    let(:resource_request_id) { 1 }
    let(:processing_errors) { ['error 1', 'error 2', 'error 3'] }

    it 'runs as expected' do
      expect(instance).to receive(:update_resource_request).with(resource_request_id: resource_request_id, status: 'failure', processing_errors: processing_errors)
      instance.resource_request_failure!(resource_request_id, processing_errors)
    end
  end

  describe '#resource_request_in_progress!' do
    let(:resource_request_id) { 1 }

    it 'runs as expected' do
      expect(instance).to receive(:update_resource_request).with(resource_request_id: resource_request_id, status: 'in_progress')
      instance.resource_request_in_progress!(resource_request_id)
    end
  end

  describe '#update_featured_thumbnail_region' do
    let(:digital_object_uid) { '1234-5678' }
    let(:featured_thumbnail_region) { '5,10,100,100' }

    let(:expected_variables) do
      {
        input: {
          id: digital_object_uid,
          featuredThumbnailRegion: featured_thumbnail_region
        }
      }
    end

    let(:expected_gql_query) do
      <<~GQL
        mutation ($input: UpdateFeaturedThumbnailRegionInput!) {
          updateFeaturedThumbnailRegion(input: $input) {
            digitalObject {
              id
            }
            userErrors {
              message
            }
          }
        }
      GQL
    end

    let(:gql_response_body) do
      { data: { updateFeaturedThumbnailRegion: { digitalObject: { id: digital_object_uid }, userErrors: [] } } }.to_json
    end

    before do
      stub_request(:post, "#{valid_client_args[:url]}/graphql").with(query: hash_including({})).to_return(status: 200, body: gql_response_body)
      expect(instance).to receive(:graphql).with(expected_gql_query, expected_variables).and_call_original
    end

    it 'performs the expected request and returns true upon success' do
      expect(instance.update_featured_thumbnail_region(digital_object_uid, featured_thumbnail_region)).to eq(true)
      expect(
        a_request(:post, "#{valid_client_args[:url]}/graphql").with(
          query: { query: expected_gql_query, variables: expected_variables.to_json },
          headers: { Faraday::Request::Authorization::KEY => expected_auth_header_value }
        )
      ).to have_been_made.once
    end

    context 'when a top level graphql error is returned' do
      let(:gql_response_body) do
        { errors: [{ path: ['path'], message: 'This is the message' }] }.to_json
      end
      it 'raises an exception' do
        expect { instance.update_featured_thumbnail_region(digital_object_uid, featured_thumbnail_region) }.to raise_error(Hyacinth::Client::Exceptions::UnexpectedResponse)
      end
    end

    context 'when a user error is returned in the data' do
      let(:gql_response_body) do
        { data: { updateFeaturedThumbnailRegion: { digitalObject: nil, userErrors: [{ message: 'This is a user error message.' }] } } }.to_json
      end
      it 'raises an exception' do
        expect { instance.update_featured_thumbnail_region(digital_object_uid, featured_thumbnail_region) }.to raise_error(Hyacinth::Client::Exceptions::UnexpectedResponse)
      end
    end
  end

  describe '.buffered_read_md5_digest' do
    let(:file_path) { file_fixture('image.jpg') }
    let(:expected_md5_base64digest) { '+zo3VVFQNvLBOqJbryFnZQ==' }

    it 'generates the expected base64digest value' do
      expect(described_class.buffered_read_md5_digest(file_path).base64digest).to eq(expected_md5_base64digest)
    end

    it 'generates the same sum as the Digest::MD5.file method' do
      # This is important because we need this method's functionality to match what ActiveStorage uses to verify checksums.
      expect(described_class.buffered_read_md5_digest(file_path).base64digest).to eq(Digest::MD5.file(file_path).base64digest)
    end
  end
end
