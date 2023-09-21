# frozen_string_literal: true

module Api
  module V1
    class DerivativeRequestsController < ApplicationApiController
      before_action :authenticate_request_token
      before_action :ensure_json_request

      # POST /api/v1/derivative_requests.json
      def create
        params_as_regular_hash = params.to_unsafe_h
        params_validation_result = Derivativo::DerivativeRequestParamsContract.new.call(params_as_regular_hash)
        if params_validation_result.errors.present?
          render json: contract_validation_error_response(params_validation_result), status: :bad_request
          return
        end
        derivative_request_job_params = params_validation_result.to_h[:derivative_request]

        DerivativeRequestJobs::PrepareDerivativeRequestJob.perform_later(**derivative_request_job_params)
        render json: { result: true }
      end

      private

      def error_response(errors)
        { result: false, errors: errors }
      end

      def contract_validation_error_response(contract_validation_result)
        error_messages = contract_validation_result.errors.map { |e| "#{e.path.join(' => ')} #{e.text}" }
        error_response(error_messages)
      end
    end
  end
end
