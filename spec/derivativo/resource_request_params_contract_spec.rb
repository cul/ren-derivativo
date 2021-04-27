# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::ResourceRequestParamsContract do
  let(:instance) { described_class.new }
  let(:job_type) { 'access_for_image' }
  let(:resource_request_id) { '1' }
  let(:digital_object_uid) { '1234-5678' }
  let(:src_file_location) { '/path/to/src/file' }
  let(:options) { { 'option1' => 'cool', 'option2' => 'also cool' } }
  let(:params_hash) do
    {
      resource_request_job: {
        job_type: job_type,
        resource_request_id: resource_request_id,
        digital_object_uid: digital_object_uid,
        src_file_location: src_file_location,
        options: options
      }
    }
  end
  let(:validation_result) { instance.call(params_hash) }
  let(:post_validation_coerced_params) { validation_result.to_h }

  it 'passes validation for an expected set of parameters' do
    expect(validation_result.errors).to be_blank
  end

  it 'performs type coercion for the resource_request_id field' do
    expect(post_validation_coerced_params[:resource_request_job][:resource_request_id]).to be_a(Integer)
  end

  context 'when resource_request_id is not an integer' do
    let(:resource_request_id) { 'not-an-integer' }
    it 'fails with the expected error' do
      expect(validation_result.errors.to_h).to eq(
        resource_request_job: { resource_request_id: ["must be an integer"] }
      )
    end
  end

  context 'when options is not a hash' do
    let(:options) { 'not-a-hash' }
    it 'fails with the expected error' do
      expect(validation_result.errors.to_h).to eq(
        resource_request_job: { options: ["must be a hash"] }
      )
    end
  end
end
