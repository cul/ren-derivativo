# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ResourceRequestJob Requests', type: :request do
  describe 'POST /api/v1/resource_request_jobs' do
    context 'when unauthenticated request' do
      it 'returns a 401 (unauthorized) status when no auth token is provided' do
        post '/api/v1/resource_request_jobs'
        expect(response.status).to eq(401)
      end

      it 'returna a 401 (unauthorized) status when an incorrect auth token is provided' do
        post '/api/v1/resource_request_jobs', headers: { 'Authorization' => 'Token NOTVALID' }
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated request' do
      let(:job_type) { 'access_for_image' }
      let(:resource_request_id) { '1' }
      let(:digital_object_uid) { '1234-5678' }
      let(:src_file_location) { '/path/to/src/file' }
      let(:options) { { 'option1' => 'cool', 'option2' => 'also cool' } }
      let(:create_params) do
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
      let(:expected_job_params) do
        job_params = create_params[:resource_request_job].except(:job_type)
        # Expect integer coercion for resource_request_id
        job_params[:resource_request_id] = job_params[:resource_request_id].to_i
        job_params
      end

      context 'when valid params are given' do
        it 'returns a 200 (ok) status ' do
          post_with_auth '/api/v1/resource_request_jobs', params: create_params
          expect(response.status).to eq(200)
        end

        it 'returns the expected response body' do
          post_with_auth '/api/v1/resource_request_jobs', params: create_params
          expect(response.body).to be_json_eql(%({"result" : true}))
        end

        it 'enqueues a the expected job type with the expected job params' do
          expect(ResourceRequestJobs::AccessForImageJob).to receive(:perform_later).with(
            **expected_job_params
          )
          post_with_auth '/api/v1/resource_request_jobs', params: create_params
        end
      end

      context 'when a non-json response format is requested' do
        it 'returns a 406 (not acceptable) status' do
          post_with_auth '/api/v1/resource_request_jobs.html', params: create_params
          expect(response.status).to eq(406)
        end
      end

      context 'when a required param is missing' do
        [:job_type, :resource_request_id, :digital_object_uid, :src_file_location].each do |required_param|
          context "when #{required_param} is missing" do
            before do
              create_params[:resource_request_job].delete(required_param)
              post_with_auth '/api/v1/resource_request_jobs', params: create_params
            end

            it 'returns a 400 (bad request) status ' do
              expect(response.status).to eq(400)
            end

            it 'returns the expected errors' do
              expect(response.body).to be_json_eql(%({
                "result" : false,
                "errors" : ["resource_request_job => #{required_param} is missing"]
              }))
            end
          end
        end
      end

      context 'when a non-hash value is given for the options param' do
        let(:options) { "I can't believe it's not hash!" }

        before do
          post_with_auth '/api/v1/resource_request_jobs', params: create_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected errors' do
          expect(response.body).to be_json_eql(%({
            "result" : false,
            "errors" : ["resource_request_job => options must be a hash"]
          }))
        end
      end

      context 'when an invalid type is given for the job_type' do
        let(:job_type) { "not-valid" }

        before do
          post_with_auth '/api/v1/resource_request_jobs', params: create_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected errors' do
          expect(response.body).to be_json_eql(%({
            "result" : false,
            "errors" : ["Job type 'not-valid' could not be resolved to a job class."]
          }))
        end
      end
    end
  end
end
