# frozen_string_literal: true

module Derivativo
  class DerivativeRequestParamsContract < Dry::Validation::Contract
    params do
      required(:derivative_request).schema do
        required(:identifier).value(:string)
        required(:delivery_target).value(:string)
        required(:main_uri).value(:string)
        required(:adjust_orientation).value(:integer, included_in?: [0, 90, 180, 270])
        required(:requested_derivatives).value(:array)
        optional(:access_uri).maybe(:string) # this means string or nil
        optional(:poster_uri).maybe(:string) # this means string or nil

        # There's a known bug related to hash validation.  We should be able to use
        # `optional(:options).value(:hash)`, but it doesn't work right now.
        # See: https://github.com/dry-rb/dry-validation/issues/682
        # TODO: After dry-validation version 2.0.0 is released, we should be able to change
        # `optional(:options).hash` to `optional(:options).value(:hash)`.
        optional(:options).hash
      end
    end

    rule(derivative_request: [:requested_derivatives]) do
      if values[:derivative_request][:requested_derivatives].reject(&:empty?).empty?
        key.failure('must be an array with at least one value')
      else
        values[:derivative_request][:requested_derivatives].each do |value|
          key.failure("value '#{value}' is not an known type") unless
            DerivativeRequest::VALID_DERIVATIVE_TYPES.include?(value)
        end
      end
    end
  end
end
