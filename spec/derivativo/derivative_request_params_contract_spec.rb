# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::DerivativeRequestParamsContract do
  let(:instance) { described_class.new }

  let(:identifier) { 'test:1' }
  let(:delivery_target) { 'hyacinth2' }
  let(:main_uri) { 'file:///path/to/file.mov' }
  let(:requested_derivatives) { ['access'] }
  let(:access_uri) { 'file:///path/to/file.mp4' }
  let(:poster_uri) { 'file:///path/to/file.tiff' }

  let(:options) { { 'option1' => 'cool', 'option2' => 'also cool' } }

  let(:required_derivative_request_params_hash) do
    {
      identifier: identifier,
      delivery_target: delivery_target,
      main_uri: main_uri,
      requested_derivatives: requested_derivatives
    }
  end
  let(:required_and_optional_derivative_request_params_hash) do
    required_derivative_request_params_hash.merge({
      access_uri: access_uri,
      poster_uri: poster_uri,
      options: options
    })
  end

  let(:validation_result) { instance.call(params_hash) }
  let(:post_validation_coerced_params) { validation_result.to_h }

  describe 'validating only required params' do
    let(:params_hash) { { derivative_request: required_derivative_request_params_hash } }

    it 'passes validation for an expected set of parameters' do
      expect(validation_result.errors).to be_blank
    end
  end

  describe 'validating required and optional params' do
    let(:params_hash) { { derivative_request: required_and_optional_derivative_request_params_hash } }

    it 'passes validation for an expected set of parameters' do
      expect(validation_result.errors).to be_blank
    end

    context 'rejects the `options` param when it is not a hash' do
      let(:options) { 'not-a-hash' }

      it 'fails with the expected error' do
        expect(validation_result.errors.to_h).to eq(
          derivative_request: { options: ['must be a hash'] }
        )
      end
    end
  end
end
