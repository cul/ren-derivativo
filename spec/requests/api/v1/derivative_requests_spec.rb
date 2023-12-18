# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/api/v1/derivative_requests', type: :request do
  describe 'POST /api/v1/derivative_requests' do
    context 'when unauthenticated request' do
      it 'returns a 401 (unauthorized) status when no auth token is provided' do
        post '/api/v1/derivative_requests'
        expect(response.status).to eq(401)
      end

      it 'returna a 401 (unauthorized) status when an incorrect auth token is provided' do
        post '/api/v1/derivative_requests', headers: { 'Authorization' => 'Token NOTVALID' }
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated request' do
      let(:identifier) { 'test:1' }
      let(:delivery_target) { 'hyacinth2' }
      let(:main_uri) { 'file:///path/to/file.mov' }
      let(:requested_derivatives) { ['access'] }
      let(:access_uri) { 'file:///path/to/file.mp4' }
      let(:poster_uri) { 'file:///path/to/file.tiff' }
      let(:adjust_orientation) { 0 }

      let(:options) { { 'option1' => 'cool', 'option2' => 'also cool' } }

      let(:create_params) do
        {
          derivative_request: {
            identifier: identifier,
            delivery_target: delivery_target,
            main_uri: main_uri,
            requested_derivatives: requested_derivatives,
            access_uri: access_uri,
            poster_uri: poster_uri,
            options: options,
            adjust_orientation: adjust_orientation
          }
        }
      end
      let(:expected_job_params) do
        create_params[:derivative_request]
      end

      context 'when valid params are given' do
        it 'returns a 200 (ok) status ' do
          post_with_auth '/api/v1/derivative_requests', params: create_params
          expect(response.status).to eq(200)
        end

        it 'returns the expected response body' do
          post_with_auth '/api/v1/derivative_requests', params: create_params
          expect(response.body).to be_json_eql(%({"result" : true}))
        end

        it 'enqueues a the expected job with the expected job params' do
          expect(DerivativeRequestJobs::PrepareDerivativeRequestJob).to receive(:perform_later).with(
            **expected_job_params
          )
          post_with_auth '/api/v1/derivative_requests', params: create_params
        end
      end

      context 'when a non-json response format is requested' do
        it 'returns a 406 (not acceptable) status' do
          post_with_auth '/api/v1/derivative_requests.html', params: create_params
          expect(response.status).to eq(406)
        end
      end

      context 'when a required param is missing' do
        [:identifier, :delivery_target, :main_uri, :requested_derivatives].each do |required_param|
          context "when required param #{required_param} is missing" do
            before do
              create_params[:derivative_request].delete(required_param)
              post_with_auth '/api/v1/derivative_requests', params: create_params
            end

            it 'returns a 400 (bad request) status ' do
              expect(response.status).to eq(400)
            end

            it 'returns the expected errors' do
              expect(response.body).to be_json_eql(%({
                "result" : false,
                "errors" : ["derivative_request => #{required_param} is missing"]
              }))
            end
          end
        end
      end

      context 'when a non-hash value is given for the options param' do
        let(:options) { "I can't believe it's not hash!" }

        before do
          post_with_auth '/api/v1/derivative_requests', params: create_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected errors' do
          expect(response.body).to be_json_eql(%({
            "result" : false,
            "errors" : ["derivative_request => options must be a hash"]
          }))
        end
      end

      context 'when an empty array is given for requested_derivatives' do
        let(:requested_derivatives) { [] }

        before do
          post_with_auth '/api/v1/derivative_requests', params: create_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected errors' do
          expect(response.body).to be_json_eql(%({
            "result" : false,
            "errors" : ["derivative_request => requested_derivatives must be an array with at least one value"]
          }))
        end
      end

      context 'when an invalid derivative type value is given for requested_derivatives' do
        let(:requested_derivatives) { ['not-valid'] }

        before do
          post_with_auth '/api/v1/derivative_requests', params: create_params
        end

        it 'returns a 400 (bad request) status' do
          expect(response.status).to eq(400)
        end

        it 'returns the expected errors' do
          expect(response.body).to be_json_eql(%({
            "result" : false,
            "errors" : ["derivative_request => requested_derivatives value 'not-valid' is not an known type"]
          }))
        end
      end
    end
  end
end
