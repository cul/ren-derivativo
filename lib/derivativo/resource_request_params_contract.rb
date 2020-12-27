# frozen_string_literal: true

module Derivativo
  class ResourceRequestParamsContract < Dry::Validation::Contract
    params do
      required(:resource_request_job).schema do
        required(:job_type).value(:string)
        required(:resource_request_id).value(:integer)
        required(:digital_object_uid).value(:string)
        required(:src_file_location).value(:string)

        # There's a known bug related to hash validation.  We should be able to use
        # `optional(:options).value(:hash)`, but it doesn't work right now.
        # See: https://github.com/dry-rb/dry-validation/issues/682
        # TODO: After dry-validation version 2.0.0 is released, we should be able to change
        # `optional(:options).hash` to `optional(:options).value(:hash)`.
        optional(:options).hash
      end
    end
  end
end
